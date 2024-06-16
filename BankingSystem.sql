create database Trg_BankingSystem

use Trg_BankingSystem
go

create Table Mastertbl
(
	acc_id int primary key,
	cname varchar(20) not null,
	NetBalance money check(NetBalance>=0) default 0,
	UnclearedBalance money default 0,
	Status varchar(20) check(Status in ('Active','Inactive')) default 'Active',
	ExceedLimit int check(ExceedLimit>=0) default 3
)

create Table Transactiontbl
(
	tid int primary key identity(1,1),
	acc_id int foreign key (acc_id) references Mastertbl(acc_id) not null,
	dot Datetime default current_timestamp,
	txn_amt money check(txn_amt>0),
	type_txn varchar(2) check (type_txn in ('CW','CD','CQ','NB'))
)

drop table Transactiontbl
drop table Mastertbl




CREATE TRIGGER trg_CreatePassbookTable
ON Mastertbl
AFTER INSERT
AS
BEGIN
    DECLARE @CustomerId INT
    DECLARE @PassbookTableName NVARCHAR(100)
    DECLARE @SQLStatement NVARCHAR(MAX)
    
    -- Get the newly inserted CustomerId
    SELECT @CustomerId = acc_id
    FROM inserted
    
    -- Generate the passbook table name
    SET @PassbookTableName = 'passbook_' + CAST(@CustomerId AS NVARCHAR(10))
    
    -- Check if the passbook table already exists
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = @PassbookTableName)
    BEGIN
        -- Construct SQL statement to create passbook table
        SET @SQLStatement = '
            CREATE TABLE ' + QUOTENAME(@PassbookTableName) + ' (
				RecordId int primary key identity(1,1),
				Tid int,
                dot Datetime,
				txn_amt money,
				type_txn varchar(2)
            )
        '
        
        -- Execute the SQL statement to create passbook table
        EXEC sp_executesql @SQLStatement
        
        PRINT 'Passbook table created for CustomerId ' + CAST(@CustomerId AS NVARCHAR(10))
    END
    ELSE
    BEGIN
        PRINT 'Passbook table already exists for CustomerId ' + CAST(@CustomerId AS NVARCHAR(10))
    END
END




-- Txn Table Validation

create procedure AccTransaction
@acc_id int,
@txn_type varchar(2),
@txn_amt money
as
begin
	if  exists (select acc_id from Mastertbl where acc_id=@acc_id)
	begin
		if @txn_type='CD'
		begin
			update Mastertbl
			set NetBalance=NetBalance+@txn_amt
			where acc_id=@acc_id

			insert into Transactiontbl(acc_id,txn_amt,type_txn) values (@acc_id,@txn_amt,'CD')
		end

		else if @txn_type='CW' or @txn_type='NB' 
		begin
			if @txn_amt<=(select NetBalance from Mastertbl where acc_id=@acc_id) and (select ExceedLimit from Mastertbl where acc_id=@acc_id)>0
			begin
				if @txn_amt<=40000
				begin
					update Mastertbl
					set NetBalance=NetBalance-@txn_amt, ExceedLimit=ExceedLimit-1
					where acc_id=@acc_id

					insert into Transactiontbl(acc_id,txn_amt,type_txn) values (@acc_id,@txn_amt,'CW')
				end

				else if @txn_amt<=100000 
				begin
					declare @amtdiff money
					set @amtdiff=@txn_amt-40000

					update Mastertbl
					set NetBalance=NetBalance-@txn_amt-@amtdiff*0.1, ExceedLimit=0
					where acc_id=@acc_id

					if @txn_type='CW'
					begin
						insert into Transactiontbl(acc_id,txn_amt,type_txn) values (@acc_id,@txn_amt,'CW')
					end
					else
					begin
						insert into Transactiontbl(acc_id,txn_amt,type_txn) values (@acc_id,@txn_amt,'NB')
					end
				end

				else
				begin
					select 'Amount limit exceeded!'
				end
			end

			else
			begin
				select 'Requested amount exceeded than current balance!'
			end
		end

		else if @txn_type='CQ'
		begin
			if @txn_amt<=(select NetBalance from Mastertbl where acc_id=@acc_id)
			begin
				update Mastertbl
				set NetBalance=NetBalance-@txn_amt
				where acc_id=@acc_id

				insert into Transactiontbl(acc_id,txn_amt,type_txn) values (@acc_id,@txn_amt,'CQ')
			end

			else
			begin
				update Mastertbl
				set UnclearedBalance=UnclearedBalance+@txn_amt
				where acc_id=@acc_id

				insert into Transactiontbl(acc_id,txn_amt,type_txn) values (@acc_id,@txn_amt,'CQ')

			end
		end

		else
		begin
			select 'Invalid transaction type!'
		end

	end

end

drop table Transactiontbl
drop table mastertbl


select * from mastertbl

insert into mastertbl(acc_id,cname) values (1,'Abc');
select * from passbook_1;

exec AccTransaction 1,'CD', 1000000
exec AccTransaction 1,'CD', 1000000
exec AccTransaction 1,'CD', 1000000

select * from mastertbl
select * from transactiontbl


exec AccTransaction 1,'CW',10000

select * from mastertbl
select * from transactiontbl

exec AccTransaction 1,'CW',100000
exec AccTransaction 1,'CQ',10000
exec AccTransaction 1,'CQ',3000000


-- Procedure to update and fetch passbook by account id
create proc UpdateAndFetchPassBookbyAccId
@acc_id int
as
begin
	declare @PassbookTableName nvarchar(100)
	declare @sqlstmt nvarchar(max)

	SET @PassbookTableName = 'passbook_' + CAST(@acc_id AS NVARCHAR(10))

	SET @sqlstmt = '
            insert into ' + QUOTENAME(@PassbookTableName) + ' 
			select Tid, dot, txn_amt, type_txn from Transactiontbl where acc_id=@acc_id and Tid not in 
			(select tid from ' + QUOTENAME(@PassbookTableName) + ')
        '
	EXEC sp_executesql @sqlstmt, N'@acc_id INT', @acc_id;

	SET @sqlstmt = ' select * from ' + QUOTENAME(@PassbookTableName)
	EXEC sp_executesql @sqlstmt;
End


exec UpdateAndFetchPassBookbyAccId 1;



insert into Mastertbl(Acc_id,cname) values (2,'Xyz');

exec AccTransaction 2,'CD',100000
exec AccTransaction 2,'CD',100000
exec AccTransaction 2,'CD',200000

exec AccTransaction 2, 'NB', 50000
exec AccTransaction 2, 'NB', 50000

exec AccTransaction 2, 'CQ', 50000


exec UpdateAndFetchPassBookbyAccId 2;