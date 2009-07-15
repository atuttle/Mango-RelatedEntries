-- create function to split list into temp table
-- function from http://fluppe.wordpress.com/2005/12/27/sql-split-string-into-table/
CREATE FUNCTION iter_charlist_to_table(
	@list      ntext,
	@delimiter nchar(1) = N','
)
RETURNS 
	@tbl TABLE (
		listpos int IDENTITY(1, 1) NOT NULL,
		str     varchar(4000),
		nstr    nvarchar(2000)
	)
AS
BEGIN
	DECLARE
		@pos      int,
		@textpos  int,
		@chunklen smallint,
		@tmpstr   nvarchar(4000),
		@leftover nvarchar(4000),
		@tmpval   nvarchar(4000)
	SET @textpos = 1
	SET @leftover = ''
	WHILE @textpos <= datalength(@list) / 2
	BEGIN
		SET @chunklen = 4000 - datalength(@leftover) / 2
		SET @tmpstr = @leftover + substring(@list, @textpos, @chunklen)
		SET @textpos = @textpos + @chunklen
		SET @pos = charindex(@delimiter, @tmpstr)
		WHILE @pos > 0
		BEGIN
			SET @tmpval = ltrim(rtrim(left(@tmpstr, @pos - 1)))
			INSERT @tbl (str, nstr) VALUES(@tmpval, @tmpval)
			SET @tmpstr = substring(@tmpstr, @pos + 1, len(@tmpstr))
			SET @pos = charindex(@delimiter, @tmpstr)
		END
		SET @leftover = @tmpstr
	END
	INSERT @tbl(str, nstr)
	VALUES (ltrim(rtrim(@leftover)), ltrim(rtrim(@leftover)))
	RETURN
END
go

--===================================

declare
	@entryId varchar(50),
	@data varchar(max),
	@count int,
	@count2 int,
	@newid varchar(5000),
	@newIdPlus varchar(5000),
	@newEntry varchar(5000), 
	@newData varchar(max)

create table #orig (
	entryId varchar(50),
	ecfid	varchar(20),
	postName varchar(500),
	data	varchar(max)
)
create table #tmp (
	listpos int NOT NULL,
	s	varchar(4000),
	n	nvarchar(2000)
)
create table #tmp2 (
	listpos int NOT NULL,
	s	varchar(4000),
	n	nvarchar(2000)
)

create table #ecf_new (id varchar(255), entry_id varchar(35), [name] varchar(255), field_value nvarchar(max))
insert into #ecf_new select * from entry_custom_field

--===================================

/* ***********************************************
	prepare bad old-format data to be fixed with reverse links
*********************************************** */

print ''
print ''
print ''
print ''
print ''
print '*******************************'
print '*******************************'
print '    preparing bad old-format data'
print '*******************************'
print '*******************************'
print ''


--get bad old-format data to be fixed
insert into #orig
	select entry_id, ecf.id, '', ecf.field_value
	from entry_custom_field ecf
	where field_value like '%@&@&@&@%'

select @count = count(entryId) from #orig

print '# of rows being updated:' + str(@count)
print ''


--loop over entries that need fixing
while (@count > 0)
begin

	--get the next entryid and bad data
	select top 1 @entryId = entryId, @data = data from #orig order by entryId desc

	print '******************************'
	print 'starting entry: ' + @entryId
	print ' - data in:' + @data

	--split the bad data into each entry
	set @data = replace(@data, '@&@&@&@', '¶')	--convert to single-character delim
	set @data = replace(@data, ',', '¶')		--strip any commas
	delete from #tmp
	insert into #tmp
	select * from iter_charlist_to_table(@data, '¶')

	set @newData = ''

	select @count2 = count(s) from #tmp

	print ' - # related entries for current entry:' + str(@count2)

	while (@count2 > 0)
	begin

		--get next related entry
		select top 1 @newIdPlus = s from #tmp order by s desc 
		
		--ignore blank rows
		if (len(@newIdPlus) > 0)
		begin
			--trim after guid
			set @newId = left(@newIdPlus, 35) --grab just the guid, not the |title

			print 'newId: ' + @newId

			set @newData = @newData + @newId
			if @count2 > 1
			begin
				set @newData = @newData + ','
			end

		end

		delete from #tmp where s = @newIdPlus

		set @count2 = @count2 - 1
	end

	--get rid of trailing commas
	while (right(@newData,1) = ',')
	begin
		set @newData = left(@newData, len(@newData)-1)
	end

	print ' - data out:' + @newData

	update #ecf_new
	set field_value = @newData
	where entry_id = @entryId
	and id = 'relEntries-b1'

	delete from #tmp

	delete from #orig where entryId = @entryId

	set @count = @count - 1
end

--delete any left-overs
delete from #orig

--===================================

/* ***********************************************
	fix reverse links and bad old-format data
*********************************************** */

print ''
print ''
print ''
print ''
print ''
print '*******************************'
print '*******************************'
print '    fixing reverse links and bad old-format data'
print '*******************************'
print '*******************************'
print ''

insert into #orig
	select e.id, ecf.id as ecfid, e.name, ecf.field_value as relEntriesData
	from entry e
	inner join #ecf_new ecf on e.id = ecf.entry_id
	where	ecf.id = 'relEntries-b1'

select @count = count(entryId) from #orig

print '# rows to update: ' + str(@count)

while (@count > 0)
begin

	--get the current record from our temp table
	select top 1 @entryId = entryid, @data = data from #orig

	print '**************************************'
	print 'starting entry: ' + @entryId
	print '  - data in: ' + @data

	--split the data element at commas into rows
	insert into #tmp (listpos, s, n)
	select * from iter_charlist_to_table(@data, ',')

	set @newData = ''
	select @count2 = count(listpos) from #tmp

	print '  - # of related entries: ' + str(@count2)

	--for each row in #tmp, build an entry for related entries data (correct format)
	while (@count2 > 0)
	begin
		select top 1 @newId = s from #tmp

		--ignore blank rows
		if (@newId <> '')
		begin
			print '  - newid: ' + @newId

			--look up the title to go with this id
			select @newEntry = '' + @newId + '|' + title
			from entry
			where id = @newid

			--if there are more to go, add an entry delimiter
			if (@count2 > 1)
			begin
				set @newEntry = @newEntry + '@&@&@&@'
			end

			print '  - newEntry: ' + @newEntry

			if (@newEntry = '@&@&@&@')
			begin
				print '  - ***** empty entry *****'
				set @newEntry = ''
			end
			
			set @newData = @newData + @newEntry

		end

		--delete from the split table
		delete from #tmp where s = @newId

		--decrement counter2
		set @count2 = @count2 - 1
	end
	
	print 'final data: ' + @newData

	--set the data back to its original home
	update #ecf_new
	set field_value = @newData
	where entry_id = @entryId
	and id = 'relEntries-b1'

	delete from #orig where entryid = @entryid

	--decrement counter1
	set @count = @count - 1
end

--===================================

--drop temp tables
drop table #tmp
drop table #tmp2
drop table #orig

--===================================

--drop temp function
drop function iter_charlist_to_table
go

--===================================

--copy final data back over to real table
delete from entry_custom_field where id='relEntries-b1'
insert into entry_custom_field (id, entry_id, [name], field_value)
select id, entry_id, [name], field_value from #ecf_new where id = 'relEntries-b1'
go

--delete temp table for results
drop table #ecf_new
