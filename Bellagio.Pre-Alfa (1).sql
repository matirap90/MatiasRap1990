USE Master
go

---- Building database -------------------------------------------------------------------------------------------------------------------

if exists (select 1 from sys.databases
	where name = 'Bellagio')
begin
	alter database Bellagio set single_user with rollback immediate
	drop database Bellagio
end
GO

CREATE DATABASE Bellagio
GO

USE Bellagio
GO

---- Creating tables in DB ---------------------------------------------------------------------------------------------------------------

-- User details

CREATE TABLE User_Details
(
	[UserID] INT PRIMARY KEY IDENTITY (1,1) ,
    [User Name] NVARCHAR(10) UNIQUE NOT NULL,
	[Password] NVARCHAR(10) NOT NULL,
    [First Name] NVARCHAR(20) NOT NULL,
	[Last Name] NVARCHAR(20) NOT NULL,
	[Address] NVARCHAR(100) DEFAULT '-',
	[Country] NVARCHAR(50) NOT NULL,
	[E-Mail] NVARCHAR(100) NOT NULL,
	[Gender] NVARCHAR(6) NOT NULL,
	[Birth Date] DATE NOT NULL,
	[Login Counter] INT DEFAULT 0 NOT NULL,
	[Login] NVARCHAR(5) DEFAULT 'NO' NOT NULL,
	[BankRoll] MONEY DEFAULT 0 NOT NULL
)
ALTER TABLE User_Details
ADD CONSTRAINT [Check.E-Mail] CHECK ([E-Mail] LIKE '%@%.%')

CREATE TABLE Country
(
	[Country Name] NVARCHAR(50) PRIMARY KEY NOT NULL
)

INSERT INTO Country
VALUES ('Afghanistan'), ('Albania'), ('Algeria'), ('Andorra'), ('Angola'), ('Argentina'), ('Armenia'), ('Australia'), ('Austria'), ('Azerbaijan'), ('Bahamas'),
('Bahrain'), ('Bangladesh'), ('Barbados'), ('Belarus'), ('Belgium'), ('Belize'), ('Benin'),	('Bolivia'), ('Bosnia and Herzegovina'), ('Botswana'), ('Brazil'),
('Bulgaria'), ('Burkina Faso'), ('Burundi'), ('Cambodia'), ('Cameroon'), ('Canada'), ('Cape Verde'), ('Chad'), ('Chile'), ('China'), ('Colombia'), ('Comoros'),
('Congo'), ('Cook Islands'), ('Costa Rica'), ('Ivory Coast'), ('Croatia'), ('Cuba'), ('Cyprus'), ('Czech Republic'), ('Democratic Republic of the Congo'), ('Denmark'),
('Dominican Republic'), ('Ecuador'), ('Egypt'), ('El Salvador'), ('Eritrea'), ('Estonia'), ('Ethiopia'), ('Fiji'), ('Finland'), ('France'), ('Gabon'), ('Gambia'),
('Georgia'), ('Germany'), ('Ghana'), ('Gibraltar'), ('Greece'), ('Guatemala'), ('Guinea'), ('Guinea-Bissau'), ('Haiti'), ('Honduras'), ('Hong Kong'), ('Hungary'),
('Iceland'), ('India'), ('Indonesia'), ('Iran'), ('Iraq'), ('Ireland'), ('Isle of Man'), ('Israel'), ('Italy'), ('Jamaica'), ('Japan'), ('Jordan'), ('Kazakhstan'),
('Kenya'), ('Kosovo'), ('Kuwait'), ('Kyrgyzstan'), ('Laos'), ('Latvia'), ('Lebanon'), ('Liberia'), ('Liechtenstein'), ('Lithuania'), ('Luxembourg'), ('Macao'), ('Macedonia'),
('Madagascar'),	('Malaysia'), ('Maldives'), ('Mali'), ('Malta'), ('Mexico'), ('Moldava'), ('Monaco'), ('Mongolia'), ('Montenegro'), ('Morocco'), ('Mozambique'),
('Myanmar'), ('Namibia'), ('Nepal'), ('Netherlands'), ('New Zealand'), ('Nicaragua'), ('Niger'), ('Nigeria'), ('North Korea'), ('Norway'), ('Oman'), ('Pakistan'), ('Palestine'),
('Panama'), ('Paraguay'), ('Peru'), ('Phillipines'), ('Poland'), ('Portugal'), ('Puerto Rico'), ('Qatar'), ('Romania'), ('Russia'), ('Rwanda'), ('Samoa'), ('San Marino'), 
('Saudi Arabia'), ('Senegal'), ('Serbia'), ('Seychelles'), ('Sierra Leone'), ('Singapore'), ('Slovakia'), ('Slovenia'), ('Solomon Islands'), ('Somalia'), ('South Africa'),
('South Korea'), ('Spain'), ('Sri Lanka'), ('Sudan'), ('Suriname'), ('Swaziland'), ('Sweden'), ('Switzerland'), ('Syria'), ('Taiwan'), ('Tajikistan'), ('Tanzania'),
('Thailand'), ('Togo'), ('Tunisia'), ('Turkey'), ('Turkmenistan'), ('Uganda'), ('Ukraine'), ('United Arab Emirates'), ('United Kingdom'), ('United States'), ('Uruguay'),
('Uzbekistan'), ('Vanuatu'), ('Venezuela'), ('Vietnam'), ('Yemen'), ('Zambia'), ('Zimbabwe')

	ALTER TABLE User_Details
	ADD CONSTRAINT FK_Country
	FOREIGN KEY (Country) REFERENCES Country ([Country Name]);

CREATE TABLE Gender 
(
	Gender NVARCHAR(6) PRIMARY KEY NOT NULL
)

INSERT INTO Gender
VALUES ('Male'), ('Female')

	ALTER TABLE User_Details
	ADD CONSTRAINT FK_Gender
	FOREIGN KEY (Gender) REFERENCES Gender (Gender);

CREATE TABLE SlotMachin_Symbols
(
 SymbolID INT PRIMARY KEY NOT NULL,
 SymbolChar NVARCHAR(1) UNIQUE NOT NULL
)

INSERT INTO SlotMachin_Symbols (SymbolID, SymbolChar)
VALUES (1,'@'), (2,'#'), (3,'$'), (4,'%'), (5,'&'), (6,'*')

CREATE TABLE GameRound
(
	RoundNumber INT PRIMARY KEY IDENTITY (1,1) NOT NULL,
	UserID INT FOREIGN KEY REFERENCES User_Details (userid),
	GameType NVARCHAR(10),
	BetAmount MONEY,
	WinOrLose NVARCHAR(5),
	Date DATETIME
)

CREATE TABLE Transaction_Type
(
  TransactionType NVARCHAR (10) PRIMARY KEY
  )

INSERT INTO Transaction_Type
VALUES ('Deposit'),('Cashout'),('Win'),('Lose'),('Bonus')

CREATE TABLE BankRoll_Trans
(
  UserID INT NOT NULL,
  TransactionNum INT IDENTITY (1,1),
  TransactionType NVARCHAR(10) ,
  Date DATETIME NOT NULL,
  Amount MONEY NOT NULL,
 
  PRIMARY KEY (TransactionNum),
  FOREIGN KEY (UserID) REFERENCES User_Details (UserID),
  FOREIGN KEY (TransactionType) REFERENCES Transaction_Type (TransactionType)
)

GO

---- Historical data ---------------------------------------------------------------------------------------------------------------------

USE [Bellagio]
IF NOT EXISTS (SELECT 0
               FROM information_schema.schemata 
               WHERE schema_name='HISTORY')
BEGIN
  EXEC sp_executesql N'CREATE SCHEMA HISTORY';
END
GO

IF not EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'start_date'
          AND Object_ID = Object_ID(N'HISTORY.User_Details'))
BEGIN
	alter table [dbo].[User_Details]
	add
	[start_date] DateTime2 generated always as row start 
		constraint DF_SysStart default SYSUTCDATETIME(),
	[end_date] DateTime2 generated always as row end 
		constraint DF_SysEnd default convert (datetime2, '9999-12-31 23:59:59.9999999'),
	PERIOD FOR SYSTEM_TIME ([start_date], [end_date]);
END

alter table [dbo].[User_Details]
	set (SYSTEM_VERSIONING = ON (HISTORY_TABLE = HISTORY.User_Details))
GO

IF not EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'start_date'
          AND Object_ID = Object_ID(N'HISTORY.GameRound'))
BEGIN
	alter table [dbo].[GameRound]
	add
	[start_date] DateTime2 generated always as row start 
		constraint DF_SysStart2 default SYSUTCDATETIME(),
	[end_date] DateTime2 generated always as row end 
		constraint DF_SysEnd2 default convert (datetime2, '9999-12-31 23:59:59.9999999'),
	PERIOD FOR SYSTEM_TIME ([start_date], [end_date]);
END

alter table [dbo].[GameRound]
	set (SYSTEM_VERSIONING = ON (HISTORY_TABLE = HISTORY.[GameRound]))
GO

---- RAND NAMBER -----------------------------------------------------------------------------------------------------------

create view [dbo].[vv_getRANDValue]
as
select rand() as value

GO

Create function [dbo].[fn_RandomNum](@Lower int, @Upper int)
returns int
as
Begin
DECLARE @Random INT;
if @Upper > @Lower
	SELECT @Random = (@Upper - @Lower) * (SELECT Value FROM vv_getRANDValue) + @Lower
Else
	SELECT @Random = (@Lower - @Upper) * (SELECT Value FROM vv_getRANDValue) + @Upper
return @Random
end

GO

---- STRONG PASSWORD --------------------------------------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].GeneratePassword ()
RETURNS varchar(6)
AS
BEGIN
  DECLARE @randInt int;
  DECLARE @NewCharacter varchar(1); 
  DECLARE @NewPassword varchar(6); 
  SET @NewPassword='';

  WHILE (LEN(@NewPassword) <3)
  BEGIN
    select @randInt=[dbo].[fn_RandomNum](48,122)
	--      0-9           < = > ? @ A-Z [ \ ]                   a-z      
    IF @randInt<=57 OR (@randInt>=60 AND @randInt<=93) OR (@randInt>=97 AND @randInt<=122)
    Begin
      select @NewCharacter=CHAR(@randInt)
      select @NewPassword=CONCAT(@NewPassword, @NewCharacter)
    END
  END

  select @NewCharacter=CHAR([dbo].[fn_RandomNum](97,122))
  select @NewPassword=CONCAT(@NewPassword, @NewCharacter)
  
  select @NewCharacter=CHAR([dbo].[fn_RandomNum](65,90))
  select @NewPassword=CONCAT(@NewPassword, @NewCharacter)

  select @NewCharacter=CHAR([dbo].[fn_RandomNum](48,57))
  select @NewPassword=CONCAT(@NewPassword, @NewCharacter)

  WHILE (LEN(@NewPassword) <6)
  BEGIN
    select @randInt=[dbo].[fn_RandomNum](33,64)
	--           !               # $ % &                            < = > ? @
    IF @randInt=33 OR (@randInt>=35 AND @randInt<=38) OR (@randInt>=60 AND @randInt<=64) 
    Begin
     select @NewCharacter=CHAR(@randInt)
     select @NewPassword=CONCAT(@NewPassword, @NewCharacter)
    END
  END

  RETURN(@NewPassword);
END;
GO
--   )

-- LOGOFF -------------------------------------------------------------------------------------------------------------------------------

CREATE or alter PROCEDURE USP_Logoff
(
@UserID int
)
As
begin
IF EXISTS (SELECT [UserID] FROM User_Details WHERE [UserID]=@UserID)
	BEGIN
	UPDATE [dbo].[User_Details]
	set Login = 'NO'
	WHERE [UserID]=@UserID
	end
END
GO

-- REGISTRATION -------------------------------------------------------------------------------------------------------------------------

CREATE or alter PROCEDURE USP_Regisration
(
@UserName NVARCHAR(10),
@Password NVARCHAR(10),
@FirstName NVARCHAR(20),
@LastName NVARCHAR(20),
@Address NVARCHAR(100),
@Country NVARCHAR(20),
@Email NVARCHAR(100),
@Gender NVARCHAR(10),
@BirthDate DATE,
@Answer NVARCHAR(100) output,
@Answer1 NVARCHAR(6) output
)
AS
BEGIN
DECLARE @AlternativeUser NVARCHAR(20)

IF EXISTS (SELECT [User Name] FROM User_Details WHERE [User Name]=@UserName)
	BEGIN
	lABEL: 
	SET @AlternativeUser=@UserName+CONVERT(NVARCHAR(2),[dbo].[fn_RandomNum](11,99))
	IF EXISTS (SELECT [User Name] FROM User_Details WHERE [User Name]=@AlternativeUser)
		GOTO LABEL
		set @Answer = 'The UserName Is already exists. You can choose another UserName: '+@AlternativeUser
		RETURN
	END

IF (@password = lower(@password) COLLATE Latin1_General_BIN)OR (@password = Upper(@password) COLLATE Latin1_General_BIN)OR (@password NOT LIKE '%[0-9]%')
	BEGIN
	set @Answer = 'You need to enter a strong password!'
	DECLARE @NewPassword NVARCHAR(6);
	exec @NewPassword = dbo.GeneratePassword
	set @Answer1 = (@NewPassword)
	RETURN
	END

IF @Password LIKE '%PASSWORD%'
	BEGIN
	set @Answer = 'Password can not be the word "password"'
	RETURN
	END

IF @Password=@UserName
	BEGIN
	set @Answer = 'Password can not be the same as user name'
	RETURN
	END

IF EXISTS (SELECT [E-Mail] FROM User_Details WHERE [E-Mail]=@Email)
	BEGIN
	set @Answer = 'The E-mail: ' + @Email + ' Is already exists.'
	RETURN
	END

IF @Email not like '%@%.%'
	BEGIN
	set @Answer = 'The email address must be in a legal email address format!'
	RETURN
	END

IF (YEAR(GETDATE())- YEAR(@birthdate))<18
	BEGIN
	set @Answer = 'sorry, You must be abov 18 years old'
	RETURN
	END

IF NOT EXISTS (SELECT [Country Name] FROM Country WHERE [Country Name]=@Country)
	BEGIN
	set @Answer = 'Country must be choosed from the list!'
	RETURN
	END

IF NOT EXISTS (SELECT Gender FROM Gender WHERE Gender=@Gender)
	BEGIN
	set @Answer = 'Gender must be choosed from the list!'
	RETURN
	END

INSERT INTO  User_Details ([User Name],Password,[First Name],[Last Name],Address,Country,[E-Mail],Gender,[Birth Date])
VALUES (@Username, @Password, @FirstName, @LastName, @Address, @Country, @Email, @Gender, @BirthDate)
set @Answer =  '***WELCOME TO CASINO ROYAL***   Get 500$ bonus'
INSERT INTO BankRoll_Trans
VALUES (@@IDENTITY, 'Bonus',GETDATE(), 500)
RETURN
END

GO

-- LOGIN --------------------------------------------------------------------------------------------------------------------------------

CREATE or alter PROCEDURE USP_LogIn
(
@UserName NVARCHAR(10),
@Password NVARCHAR(10),
@Answer NVARCHAR(40) output,
@Money NVARCHAR(40) output,
@id int output
)
AS
IF EXISTS (SELECT [User Name],Password FROM User_Details WHERE [User Name]=@UserName AND Password=@Password)
BEGIN
	IF (SELECT [Login] FROM User_Details WHERE [User Name]=@UserName)='YES'
		BEGIN 
		set @Answer = 'You are already loged in'
		RETURN
		END
	ELSE
		BEGIN
		set @Answer = 'You Loged in secssecfuly'
		DECLARE @Bankroll money =(SELECT bankroll from User_Details WHERE [User Name]=@Username)
		set @Money = 'Your bank roll is '+ CONVERT(NVARCHAR,@Bankroll)
		UPDATE User_Details SET [Login] = 'YES' where [User Name]=@UserName
		UPDATE User_Details SET[Login counter] = 0 where [User Name]=@UserName
		set @id = (SELECT [UserID] from User_Details WHERE [User Name]=@Username and [Password]=@Password) 
		RETURN
		END
RETURN
END
ELSE
	IF (SELECT [Login counter] FROM User_Details WHERE [User Name]=@UserName)<5
	BEGIN 
	set @Answer = 'User or password is incorect'
	UPDATE User_Details SET [Login counter] = [Login counter]+1 where [User Name]=@UserName
	RETURN
	END
	ELSE	
	if not EXISTS (select [User Name] from [dbo].[User_Details] where [User Name]=@UserName)
	set @Answer = 'User not exists'
	else
	set @Answer = 'You are blocked, please call the support'

GO

-- UNBLOCK ------------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE USP_UnBlock
(
@UserId INT
)
AS 
BEGIN
DECLARE @RandPassword NVARCHAR(6)
SET @RandPassword=dbo.GeneratePassword ()
UPDATE User_Details SET password=@RandPassword WHERE UserID=@UserId
UPDATE User_Details SET [Login counter]=0 WHERE UserID=@UserId
PRINT 'Your new password is:'
PRINT @RandPassword
RETURN
END

GO


-- Chashier ----------------------------------------------------------------------------------------------------------------------------

CREATE or alter PROCEDURE USP_Chashier
(
@UserID int, 
@Amount money, 
@TransactionType Nvarchar(10),
@Answer NVARCHAR(100) output
)
AS
IF @TransactionType='Cashout'
	IF @Amount>(SELECT BankRoll FROM User_Details WHERE @UserID=UserID)
	BEGIN
	set @Answer = 'The amount you have is less than the amount you want to Cashout. Please Try Again.'
	RETURN
	END
IF @TransactionType='Cashout'
	begin
	INSERT INTO BankRoll_Trans (UserID , TransactionType, Date, Amount)
	VALUES (@UserID, @TransactionType , GETDATE(), @Amount*(-1))
	set @Answer = 'Cashout succesfully'
	end	
IF @TransactionType='Deposit'
	begin
	INSERT INTO BankRoll_Trans (UserID , TransactionType, Date, Amount)
	VALUES (@UserID, @TransactionType , GETDATE(), @Amount)
	set @Answer = 'Deposit succesfully'
	END

GO

-- GAMESM -------------------------------------------------------------------------------------------------------------------------------

CREATE or alter PROCEDURE USP_GameSM
(
@UserId INT,
@BetAmount INT,
@Answer nvarchar(100) output
)
AS
IF @BetAmount>(SELECT BankRoll FROM User_Details WHERE UserID=@UserId)
	BEGIN 
	set @Answer = 'You can only bet on amount of money you have in your bankroll. please go to the Cachier or reduce your bet amount'
	RETURN
	END
ELSE
	BEGIN
	DECLARE @Symbol1 NVARCHAR(5), @Symbol2 NVARCHAR(5), @Symbol3 NVARCHAR(5), @WinOrLose NVARCHAR(10)
	SET @Symbol1=(SELECT TOP 1 SymbolChar FROM SlotMachin_Symbols ORDER BY NEWID())
	SET @Symbol2=(SELECT TOP 1 SymbolChar FROM SlotMachin_Symbols ORDER BY NEWID())
	SET @Symbol3=(SElECT TOP 1 SymbolChar FROM SlotMachin_Symbols ORDER BY NEWID())
	IF (@Symbol1=@Symbol2) and (@Symbol2=@Symbol3)
		BEGIN
		set @Answer = 'you won! '+CONVERT(CHAR(10),@BetAmount)+'$!'
		SET @WinOrLose='Win'
		INSERT INTO BankRoll_Trans (UserId, TransactionType, DATE, Amount)
		VALUES (@UserId, @WinOrLose, GETDATE(), @BetAmount)
		END
	ELSE
		BEGIN
		set @Answer = 'Sorry, you lose this time. you can try your luck again..'
		SET @WinOrLose='Lose'
		INSERT INTO BankRoll_Trans (UserId, TransactionType, DATE, Amount)
		VALUES (@UserId, @WinOrLose, GETDATE(), @BetAmount*(-1))
		END
	END
INSERT INTO GameRound (UserID, GameType, BetAmount, WinOrLose, Date)
VALUES (@UserId,'SlotMachin',@BetAmount, @WinOrLose, GETDATE())

GO

-- GAMEHR -------------------------------------------------------------------------------------------------------------------------------

create or alter proc USP_HorseRace
(
@UserId INT,
@BetAmount INT,
@Bet_Horse INT,
@Answer nvarchar(100) output
)
as

DECLARE
	@Horse1Position				as tinyint		= 0 ,
	@Horse2Position				as tinyint		= 0 ,
	@Horse3Position				as tinyint		= 0 ,
	@Horse4Position				as tinyint		= 0 ,
	@Horse5Position				as tinyint		= 0 ,
	@MaxHorsePosition			as tinyint		= 0 ,
	@MaxTrackPosition			as tinyint		= 20,
	@MaxStepsPerIteration		as tinyint		= 6 ,
	@Winner						as tinyint ,
	@LineToPrint				as nvarchar(max) ,
	@WinOrLose NVARCHAR(10);

WHILE
	1 = 1
BEGIN

	SET @LineToPrint = REPLICATE (N'.' , @Horse1Position) + N'1' + 
	REPLICATE (N'.' , @MaxTrackPosition - @Horse1Position);
	RAISERROR (@LineToPrint , 0 , 1) WITH NOWAIT

	SET @LineToPrint = REPLICATE (N'.' , @Horse2Position) + N'2' + 
	REPLICATE (N'.' , @MaxTrackPosition - @Horse2Position);
	RAISERROR (@LineToPrint , 0 , 1) WITH NOWAIT

	SET @LineToPrint = REPLICATE (N'.' , @Horse3Position) + N'3' + 
	REPLICATE (N'.' , @MaxTrackPosition - @Horse3Position);
	RAISERROR (@LineToPrint , 0 , 1) WITH NOWAIT

	SET @LineToPrint = REPLICATE (N'.' , @Horse4Position) + N'4' + 
	REPLICATE (N'.' , @MaxTrackPosition - @Horse4Position);
	RAISERROR (@LineToPrint , 0 , 1) WITH NOWAIT

	SET @LineToPrint = REPLICATE (N'.' , @Horse5Position) + N'5' + 
	REPLICATE (N'.' , @MaxTrackPosition - @Horse5Position);
	RAISERROR (@LineToPrint , 0 , 1) WITH NOWAIT

	RAISERROR (N'' , 0 , 1) WITH NOWAIT;

	IF
		@MaxHorsePosition = @MaxTrackPosition
	BEGIN
	
		BREAK;

	END;

	SET @Horse1Position += CAST ((RAND () * (@MaxStepsPerIteration + 1)) as tinyint) %
		(@MaxStepsPerIteration + 1);

	IF
		@Horse1Position > @MaxTrackPosition
	BEGIN
		SET @Horse1Position = @MaxTrackPosition
	END;

	IF
		@Horse1Position > @MaxHorsePosition
	BEGIN
		SET @MaxHorsePosition = @Horse1Position
		SET @Winner = 1;
	END;

	SET @Horse2Position += CAST ((RAND () * (@MaxStepsPerIteration + 1)) as tinyint) %
		(@MaxStepsPerIteration + 1);

	IF
		@Horse2Position > @MaxTrackPosition
	BEGIN
		SET @Horse2Position = @MaxTrackPosition
	END;

	IF
		@Horse2Position > @MaxHorsePosition
	BEGIN
		SET @MaxHorsePosition = @Horse2Position
		SET @Winner = 2;
	END;

		SET @Horse3Position += CAST ((RAND () * (@MaxStepsPerIteration + 1)) as tinyint) %
		(@MaxStepsPerIteration + 1);

	IF
		@Horse3Position > @MaxTrackPosition
	BEGIN
		SET @Horse3Position = @MaxTrackPosition
	END;

	IF
		@Horse3Position > @MaxHorsePosition
	BEGIN
		SET @MaxHorsePosition = @Horse3Position
		SET @Winner = 3;
	END;

		SET @Horse4Position += CAST ((RAND () * (@MaxStepsPerIteration + 1)) as tinyint) %
		(@MaxStepsPerIteration + 1);

	IF
		@Horse4Position > @MaxTrackPosition
	BEGIN
		SET @Horse4Position = @MaxTrackPosition
	END;

	IF
		@Horse4Position > @MaxHorsePosition
	BEGIN
		SET @MaxHorsePosition = @Horse4Position
		SET @Winner = 4;
	END;

		SET @Horse5Position += CAST ((RAND () * (@MaxStepsPerIteration + 1)) as tinyint) %
		(@MaxStepsPerIteration + 1);

	IF
		@Horse5Position > @MaxTrackPosition
	BEGIN
		SET @Horse5Position = @MaxTrackPosition
	END;

	IF
		@Horse5Position > @MaxHorsePosition
	BEGIN
		SET @MaxHorsePosition = @Horse5Position
		SET @Winner = 5;
	END;
	
	WAITFOR DELAY '00:00:01'

END;
begin
	SET @LineToPrint = N'The winner is horse #' + CAST (@Winner as nvarchar(MAX)) + N'!';
	set @Answer = @LineToPrint
end
IF @Winner = @Bet_Horse
		BEGIN
		set @Answer = 'you won! '+CONVERT(CHAR(10),@BetAmount)+'$!'
		SET @WinOrLose='Win'
		INSERT INTO BankRoll_Trans (UserId, TransactionType, DATE, Amount)
		VALUES (@UserId, @WinOrLose, GETDATE(), @BetAmount)
		END
	ELSE
		BEGIN
		set @Answer = 'Sorry, you lose this time. you can try your luck again..'
		SET @WinOrLose='Lose'
		INSERT INTO BankRoll_Trans (UserId, TransactionType, DATE, Amount)
		VALUES (@UserId, @WinOrLose, GETDATE(), @BetAmount*(-1))
		END

GO

-- BANKROLL -----------------------------------------------------------------------------------------------------------------------------

CREATE TRIGGER Bankroll_Insert
ON BankRoll_Trans
FOR INSERT
AS
BEGIN
UPDATE User_Details
SET BankRoll = (U.bankroll + I.Amount)
FROM User_Details AS U INNER JOIN Inserted AS I
ON U.UserID = I.UserID
where I.TransactionNum= TransactionNum
END

GO	

--Reports--------------------------------------------------------------------------------------------------------------------------------

-- Game history Report ------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION DBO.Game_History_Report(@UserName NVARCHAR(20))
RETURNS @TABLE TABLE (GameType NVARCHAR(10),RoundNumber int, BetAmount MONEY,WinOrLose NVARCHAR(5), Date DATETIME)
AS
BEGIN
INSERT INTO @TABLE (GameType, RoundNumber, BetAmount, WinOrLose, Date)
SELECT GR.GameType, ROW_NUMBER() OVER (PARTITION BY GR.UserID ORDER BY GR.Date DESC) RoundNumber, GR.BetAmount, GR.WinOrLose, GR.Date
FROM GameRound GR JOIN User_Details UN
ON GR.UserID=UN.UserID
WHERE UN.[User Name] = @UserName
ORDER BY GR.Date DESC
RETURN
END

GO


-- Bankyoll Transaction -----------------------------------------------------------------------------------------------------------------
CREATE FUNCTION DBO.Bankroll_Transactions_Report(@UserName NVARCHAR(20), @BeginDate NVARCHAR(20), @EndDate NVARCHAR(20))
RETURNS TABLE
RETURN  
SELECT TransactionOfUser, BRT.TransactionNum, BRT.TransactionType, CONVERT(NVARCHAR,DATE,103) Date, BRT.Amount, SUM(BRT.Amount) OVER (PARTITION BY BRT.UserID ORDER BY BRT.TransactionNum) 'BankRoll'
FROM
(SELECT BRT.UserID ,BRT.TransactionNum, BRT.TransactionType, BRT.DATE, BRT.Amount, ROW_NUMBER() OVER (PARTITION BY BRT.UserID ORDER BY BRT.UserID) AS 'TransactionOfUser'
FROM BankRoll_Trans BRT join User_Details UN
ON BRT.UserID = UN.UserID
WHERE UN.[User Name] = @UserName AND CONVERT(NVARCHAR,DATE,103) BETWEEN @BeginDate AND @EndDate) BRT

GO

-- Game Statistics Report ---------------------------------------------------------------------------------------------------------------

CREATE VIEW UVW_Game_Statistics_Report AS
SELECT CS.Date, CS.[Number of Rounds], CS.[Number of Winning], CS.[Total Bet Amount], ISNULL(CS.[Total Winning Amount],0) AS 'Total Winning Amount'
FROM
(SELECT CONVERT(NVARCHAR,Date,103) AS Date , COUNT(RoundNumber) AS 'Number of Rounds', COUNT(WinOrLose) 'Number of Winning', SUM(BetAmount) 'Total Bet Amount',
(SELECT SUM(Amount) FROM BankRoll_Trans WHERE TransactionType = 'Win') 'Total Winning Amount'
FROM GameRound
WHERE Date BETWEEN GETDATE()-7 AND GETDATE()
GROUP BY CONVERT(NVARCHAR,Date,103)) CS

GO