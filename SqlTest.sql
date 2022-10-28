use InnowiseTest

CREATE TABLE Banks(
  Id  INT PRIMARY KEY,
  Name NVARCHAR(20),
);

CREATE TABLE Cities(
 Id INT PRIMARY KEY,
 BankId INT FOREIGN KEY REFERENCES Banks (Id),
 Name Nvarchar(20)
);

CREATE TABLE Filials(
 Id INT PRIMARY KEY,
 CityId INT FOREIGN KEY REFERENCES Cities (Id),
 Adress NVARCHAR(20),

);
CREATE TABLE SocialStatus(
  Id INT PRIMARY KEY,
  SocialStatus NVARCHAR(20)
)

CREATE TABLE Client(
 Id INT PRIMARY KEY,
 SocialStatusId INT FOREIGN KEY REFERENCES SocialStatus (Id),
 ClientName NVARCHAR(20),
)

CREATE TABLE BanksClient(
 BankId INT FOREIGN KEY REFERENCES Banks (Id),
 ClientId INT FOREIGN KEY REFERENCES Client (Id)
);

CREATE TABLE Account(
 Id int PRIMARY KEY FOREIGN KEY REFERENCES Client(Id),
 AccountNumber nvarchar(30),
 AccountBalance INT
)

CREATE TABLE Cards(
 Id INT PRIMARY KEY,
 AccountId INT FOREIGN KEY REFERENCES Account (Id),
 CardNumber nvarchar(20),
 Balance INT ,
)



INSERT INTO Banks 
VALUES(0,'Mbank'),
      (1,'PriorBank'),
	  (2,'AlfaBank'),
	  (3,'BelarusBank'),
	  (4,'BelInvestBank'),
	  (5,'Belagroprom')

INSERT INTO Cities
VALUES(0,2,'Minsk'),
      (1,4,'Moscow'),
	  (2,3,'Moscow'),
	  (3,0,'Vilnues'),
	  (4,1,'Minsk'),
	  (5,5,'Moscow')

INSERT INTO Filials
VALUES(0,2,'Lenina'),
      (1,1,'Kononovicha'),
	  (2,0,'Dark'),
	  (3,3,'Ignatovskogo'),
	  (4,4,'Lenina'),
	  (5,3,'Ignatovskogo')

INSERT INTO SocialStatus
VALUES (0,'STUDENT'),
	   (1,'WORKER'),
       (2,'INVALID'),
       (3,'SPORTSMEN')

INSERT INTO Client
VALUES (0,3,'OLEG'),
       (1,2,'ROMA'),
	   (2,3,'MAKSIM'),
	   (3,2,'REX'),
	   (4,0,'SASHA'),
	   (5,1,'MICHAIL'),
	   (6,1,'LESHA')

INSERT INTO BanksClient
VALUES (3,2),
       (2,4),
	   (1,0),
	   (0,1),
	   (4,3)

INSERT INTO Account 
VALUES (0,'123mkdkc42kmx',20603),
       (1,'1ed3w3dsvrv4d',2390),
	   (2,'mmkekcm2324mk',230),
	   (3,'eeccsd3232dxw',335),
	   (4,'cmkmckemsmsmx',31214),
	   (5,'rrvrvrerrvrr',4000)

INSERT INTO Cards 
VALUES (0,2,'1342332432',230),
	   (1,3,'1342354662',323),
	   (2,4,'6434332432',10002),
	   (3,3,'8483483884',12),
	   (4,0,'9323212122',403),
	   (5,1,'2353422323',890),
	   (6,1,'4534334323',1500),
	   (7,4,'7482382388',19929),
	   (8,0,'1324342323',20200),
	   (9,4,'6434343434',1212),
	   (10,5,'3232113131',1000),
	   (11,5,'3442196131',2000)

--1
SELECT Banks.Name
FROM Banks
inner join Cities on Banks.Id = Cities.BankId
inner join Filials on Cities.Id = Filials.CityId
Where Cities.Name = 'Moscow' 

--2
SELECT Cards.CardNumber , Cards.Balance, Client.ClientName, Banks.Name
FROM Cards 
     INNER JOIN Account on Cards.AccountId = Account.Id
	 INNER JOIN Client on Account.Id = Client.Id
	 INNER JOIN BanksClient on Client.Id = BanksClient.ClientId
	 INNER JOIN Banks on BanksClient.BankId = Banks.Id

--3
SELECT  Account.AccountNumber , Account.AccountBalance - (SUM(Cards.Balance)) as Diff
FROM Account 
            INNER JOIN Cards on Account.Id = Cards.AccountId
		    WHERE Account.AccountBalance != (Select sum(Cards.Balance) from Cards
									 where Account.Id = Cards.AccountId)
			GROUP BY Account.Id, Account.AccountNumber, Account.AccountBalance

--4-1
SELECT SocialStatus.SocialStatus , COUNT(*) AS CardsNumber
FROM Cards 
          INNER JOIN Account on Cards.AccountId = Account.Id
		  INNER JOIN Client on Account.Id = Client.Id
		  INNER JOIN SocialStatus on SocialStatus.Id = Client.SocialStatusId
		  GROUP BY SocialStatus.SocialStatus

--4-2
SELECT SocialStatus.SocialStatus,(SELECT  COUNT(*) FROM  Cards
							INNER JOIN Account on Cards.AccountId = Account.Id
						    INNER JOIN Client on Account.Id = Client.Id
						 WHERE Client.SocialStatusId = SocialStatus.Id) AS CountOfCards
FROM SocialStatus

--5		
GO
CREATE PROCEDURE AddMoneyToAccounts @SocialStatusId INT AS
	BEGIN TRY
		UPDATE Account SET AccountBalance += 10 FROM Account
			INNER JOIN Client on Account.Id = Client.Id
			INNER JOIN SocialStatus on Client.SocialStatusId = SocialStatus.Id
		WHERE @SocialStatusId = SocialStatus.Id
	END TRY
	BEGIN CATCH 
	   PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER()) + ':' + ERROR_MESSAGE()
	END CATCH

SELECT Account.AccountBalance FROM Account
EXEC AddMoneyToAccounts 6
SELECT Account.AccountBalance FROM Account

--6 
SELECT Account.AccountBalance - SUM(Cards.Balance),Client.ClientName FROM Cards 
INNER JOIN Account on Account.Id = Cards.AccountId
INNER JOIN Client on Account.Id = Client.Id
GROUP BY Account.Id,Client.ClientName,AccountBalance

--7
GO
CREATE PROCEDURE TranslateMoneyToCard @countToTranfer int, @accountId int,@cardId int AS
	BEGIN TRAN
	    DECLARE @balance int,@sumOfCardsBalance int;
		SELECT  @balance=Account.AccountBalance, @sumOfCardsBalance = SUM(Cards.Balance) from Account
			    INNER JOIN Cards on Account.Id = Cards.AccountId 
			WHERE Account.Id = @accountId
			GROUP BY Account.Id , Account.AccountBalance
		if (@balance < @sumOfCardsBalance+@countToTranfer)
		ROLLBACK
		ELSE 
		UPDATE Cards SET Balance += @countToTranfer WHERE @cardId = Cards.Id
COMMIT TRAN

SELECT Account.AccountBalance,Cards.Balance from Account
       INNER JOIN Cards on Cards.AccountId = Account.Id
	   WHERE Cards.Id =10 or Cards.Id = 11

EXEC  TranslateMoneyToCard 20000 , 5,10

SELECT Account.AccountBalance,Cards.Balance from Account
       INNER JOIN Cards on Cards.AccountId = Account.Id
	   WHERE Cards.Id =10 or Cards.Id = 11

GO
--8
ALTER TRIGGER Update_AccountBalance 
 ON Account
 INSTEAD OF UPDATE 
 AS
 BEGIN TRAN
 DECLARE @id INT = (SELECT INSERTED.Id FROM INSERTED)
 DECLARE @accountBalanceForUpdate  INT = (SElECT INSERTED.AccountBalance FROM INSERTED)
 DECLARE @sumOfCardsBalance INT;
 SET @sumOfCardsBalance = (SELECT SUM(Cards.Balance) FROM Account 
                   INNER JOIN Cards on Account.Id = Cards.AccountId WHERE Account.Id = @id)

 IF (@accountBalanceForUpdate  < @sumOfCardsBalance)
 BEGIN 
	 RAISERROR ('Account balance can t be less then sum of cards balance',1,3);
	 ROllBACK
 END
 ELSE 
 BEGIN
	 UPDATE Account SET AccountBalance = @accountBalanceForUpdate
	 WHERE Account.Id = @id;
	 PRINT('SUCCESS');
	 COMMIT
 END

 GO
 CREATE TRIGGER Update_CardsBalance 
 on Cards
 INSTEAD OF UPDATE 
 AS 
 BEGIN TRAN 
	 DECLARE @id INT = (SELECT INSERTED.Id FROM INSERTED)
	 DECLARE @accountId INT = (SELECT INSERTED.AccountId FROM INSERTED)
	 DECLARE @currentCardsBalance  INT = (SElECT Cards.Balance FROM Cards WHERE Cards.Id = @id);
	 DECLARE @cardsBalanceForUpdate  INT = (SElECT INSERTED.Balance FROM INSERTED)
	 DECLARE @sumOfCardsBalance INT;
	 DECLARE @accountBalance INT;

	 SET @accountBalance = (SELECT Account.AccountBalance FROM Account WHERE Account.Id = @accountId)
	 SET @sumOfCardsBalance = (SELECT SUM(Cards.Balance) FROM Account 
                   INNER JOIN Cards on Account.Id = Cards.AccountId WHERE Cards.AccountId = @accountId)
	 IF ((@accountBalance-@sumOfCardsBalance)<(@cardsBalanceForUpdate-@currentCardsBalance))
	 BEGIN
	    RAISERROR ('Account balance can t be less then sum of cards balance',1,3);
		ROLLBACK 
	 END 
	 ELSE
		 BEGIN
		    PRINT('SUCCESS');
			UPDATE Cards SET Balance = @cardsBalanceForUpdate WHERE Cards.Id = @id
		 END 
COMMIT

 UPDATE Account SET AccountBalance = 1000 WHERE Account.Id = 1
 UPDATE Cards SET Balance = 100 WHERE Cards.Id = 1

DROP TABLE Banks
DROP TABLE Filials
DROP TABLE Cities
DROP TABLE Client
DROP TABLE BanksClient
DROP TABLE Account
DROP TABLE Cards
DROP TABLE SocialStatus


