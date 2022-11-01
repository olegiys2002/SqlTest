use InnowiseTest

CREATE TABLE Banks(
  Id  INT PRIMARY KEY,
  Name NVARCHAR(20),
);

CREATE TABLE Cities(
 Id INT PRIMARY KEY,
 Name Nvarchar(20)
);

CREATE TABLE Filials(
 Id INT PRIMARY KEY,
 BankId INT FOREIGN KEY REFERENCES Banks (Id),
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

CREATE TABLE Account(
 BankId INT FOREIGN KEY REFERENCES Banks (Id),
 ClientId INT FOREIGN KEY REFERENCES Client (Id),
 AccountNumber nvarchar(30),
 AccountBalance INT,
 PRIMARY KEY (BankId,ClientId),
 UNIQUE (BankId,ClientId)
)

CREATE TABLE Cards(
 Id INT PRIMARY KEY,
 ClientId INT FOREIGN KEY REFERENCES Client (Id),
 BankId INT FOREIGN KEY REFERENCES Banks (Id),
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
VALUES(0,'Minsk'),
      (1,'Moscow'),
	  (2,'Moscow'),
	  (3,'Vilnues'),
	  (4,'Minsk'),
	  (5,'Moscow')

INSERT INTO Filials
VALUES(0,2,2,'Lenina'),
      (1,3,1,'Kononovicha'),
	  (2,4,0,'Dark'),
	  (3,5,3,'Ignatovskogo'),
	  (4,1,4,'Lenina'),
	  (5,1,3,'Ignatovskogo')

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

INSERT INTO Account 
VALUES (0,2,'123mkdkc42kmx',23370),
       (1,3,'1ed3w3dsvrv4d',23900),
	   (2,0,'mmkekcm2324mk',2300),
	   (3,1,'eeccsd3232dxw',33500),
	   (4,5,'cmkmckemsmsmx',31214),
	   (5,4,'rrvrvrerrvrr',40000),
	   (5,6,'rrvrvr33rvrr',3000)

INSERT INTO Cards 
VALUES (0,0,2,'1342332432',230),
	   (1,2,3,'1342354662',323),
	   (2,4,4,'6434332432',10002),
	   (3,3,3,'8483483884',12),
	   (4,4,0,'9323212122',403),
	   (5,1,1,'2353422323',890),
	   (6,5,1,'4534334323',1500),
	   (7,3,4,'7482382388',19929),
	   (8,2,0,'1324342323',20200),
	   (9,1,4,'6434343434',1212),
	   (10,1,5,'3232113131',1000),
	   (11,3,5,'3442196131',2000)


CREATE INDEX BankId on Filials (BankId)
CREATE INDEX CityId on Filials (CityId)
CREATE INDEX ClientId on Cards (ClientId)
CREATE INDEX BankCardId on Cards (BankId)
CREATE INDEX SocialStatusId on Filials (CityId)
--1
SELECT Banks.Name
FROM Banks
inner join Filials on Banks.Id = Filials.BankId
inner join Cities on Filials.CityId = Cities.Id
Where Cities.Name = 'Moscow' 

--2
SELECT Cards.CardNumber , Cards.Balance, Client.ClientName, Banks.Name
FROM Cards 
    INNER JOIN Banks on Cards.BankId = Banks.Id
	INNER JOIN Client on Cards.ClientId = Client.Id

--3
SELECT  Account.AccountNumber , Account.AccountBalance - (SUM(Cards.Balance)) as Diff
FROM Account 
			INNER JOIN Client on Account.BankId = Client.Id 
            INNER JOIN Cards on Client.Id = Cards.ClientId
		    WHERE Account.AccountBalance != (SELECT SUM(Cards.Balance) FROM Cards
									         WHERE Client.Id = Cards.ClientId)
			GROUP BY Account.ClientId, Account.AccountNumber, Account.AccountBalance

--4-1
SELECT SocialStatus.SocialStatus , COUNT(*) AS CardsNumber
FROM Cards 
			INNER JOIN Client on Cards.ClientId = Client.Id
			INNER JOIN SocialStatus on SocialStatus.Id = Client.SocialStatusId
		 GROUP BY SocialStatus.SocialStatus

--4-2
SELECT SocialStatus.SocialStatus,(SELECT  COUNT(*) FROM  Cards
							INNER JOIN Client on Cards.ClientId = Client.Id
						 WHERE Client.SocialStatusId = SocialStatus.Id) AS CountOfCards
FROM SocialStatus

--5		
GO
CREATE PROCEDURE AddMoneyToAccounts @SocialStatusId INT AS
	BEGIN TRY
		UPDATE Account SET AccountBalance += 10 FROM Account
			INNER JOIN Client on Account.ClientId = Client.Id
			INNER JOIN SocialStatus on Client.SocialStatusId = SocialStatus.Id
		WHERE @SocialStatusId = SocialStatus.Id
	END TRY
	BEGIN CATCH 
	   PRINT 'Error ' + CONVERT(VARCHAR, ERROR_NUMBER()) + ':' + ERROR_MESSAGE()
	END CATCH

SELECT Account.AccountBalance FROM Account
EXEC AddMoneyToAccounts 1
SELECT Account.AccountBalance FROM Account

--6 
SELECT Account.AccountBalance - SUM(Cards.Balance),Client.ClientName FROM Cards 
INNER JOIN Client on Cards.ClientId = Client.Id
INNER JOIN Account on Client.Id = Account.ClientId 
GROUP BY Account.ClientId,Client.ClientName,AccountBalance

--7
GO
ALTER PROCEDURE TranslateMoneyToCard @countToTranfer int, @accountId int,@cardId int AS
	BEGIN TRAN
	    DECLARE @balance int,@sumOfCardsBalance int;
		SELECT  @balance=Account.AccountBalance, @sumOfCardsBalance = SUM(Cards.Balance) from Account
			    INNER JOIN Client on Client.Id = Account.ClientId 
				INNER JOIN Cards on Client.Id = Cards.ClientId
			WHERE Account.ClientId = @accountId
			GROUP BY Account.ClientId , Account.AccountBalance
		if (@balance < @sumOfCardsBalance+@countToTranfer)
		ROLLBACK
		ELSE 
		UPDATE Cards SET Balance += @countToTranfer WHERE @cardId = Cards.Id
COMMIT TRAN

SELECT Account.AccountBalance,Cards.Balance from Account
       INNER JOIN Client on Client.Id = Account.ClientId 
	   INNER JOIN Cards on Client.Id = Cards.ClientId
	   WHERE Cards.Id =6 

EXEC  TranslateMoneyToCard 100000 , 5,6

SELECT Account.AccountBalance,Cards.Balance from Account
       INNER JOIN Client on Client.Id = Account.ClientId 
	   INNER JOIN Cards on Client.Id = Cards.ClientId
	   WHERE Cards.Id =6 

GO
--8
CREATE TRIGGER Update_AccountBalance 
 ON Account
 INSTEAD OF UPDATE 
 AS
 BEGIN TRAN
 DECLARE @id INT = (SELECT INSERTED.ClientId FROM INSERTED)
 DECLARE @accountBalanceForUpdate  INT = (SElECT INSERTED.AccountBalance FROM INSERTED)
 DECLARE @sumOfCardsBalance INT;
 SET @sumOfCardsBalance = (SELECT SUM(Cards.Balance) FROM Account 
							INNER JOIN Client on Client.Id = Account.ClientId 
							INNER JOIN Cards on Client.Id = Cards.ClientId
						   WHERE Account.ClientId = @id)

 IF (@accountBalanceForUpdate  < @sumOfCardsBalance)
 BEGIN 
	 RAISERROR ('Account balance can t be less then sum of cards balance',1,3);
	 ROllBACK
 END
 ELSE 
 BEGIN
	 UPDATE Account SET AccountBalance = @accountBalanceForUpdate
	 WHERE Account.ClientId = @id;
	 PRINT('SUCCESS');
	 COMMIT TRAN
 END

 GO
 ALTER TRIGGER Update_CardsBalance 
 on Cards
 INSTEAD OF UPDATE 
 AS 
 BEGIN TRAN 
	 DECLARE @id INT = (SELECT INSERTED.Id FROM INSERTED)
	 DECLARE @clientId INT = (SELECT INSERTED.ClientId FROM INSERTED)
	 DECLARE @currentCardsBalance  INT = (SElECT Cards.Balance FROM Cards WHERE Cards.Id = @id);
	 DECLARE @cardsBalanceForUpdate  INT = (SElECT INSERTED.Balance FROM INSERTED)
	 DECLARE @sumOfCardsBalance INT;
	 DECLARE @accountBalance INT;

	 SET @accountBalance = (SELECT Account.AccountBalance FROM Account WHERE Account.ClientId = @clientId)
	 SET @sumOfCardsBalance = (SELECT SUM(Cards.Balance) FROM Cards
								INNER JOIN Client on Client.Id = Cards.ClientId
							   WHERE Cards.ClientId = @clientId)
	 IF ((@accountBalance-@sumOfCardsBalance) < (@cardsBalanceForUpdate-@currentCardsBalance))
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

 UPDATE Account SET AccountBalance = 40000 WHERE Account.ClientId = 1
 UPDATE Cards SET Balance = 100 WHERE Cards.Id = 1

DROP TABLE Banks
DROP TABLE Filials
DROP TABLE Cities
DROP TABLE Client
DROP TABLE Account
DROP TABLE Cards
DROP TABLE SocialStatus



