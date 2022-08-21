--CREATE DATABASE
USE master
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'FIT_N_FINE')
	DROP DATABASE FIT_N_FINE
GO

CREATE DATABASE FIT_N_FINE
GO

--USING THE DATABASE
USE FIT_N_FINE
GO

---CREATING OUR DATA TYPE
CREATE TYPE NAMES FROM VARCHAR(25)
CREATE TYPE Numb FROM VARCHAR(15) 
CREATE TYPE Gend FROM VARCHAR(6) 
CREATE TYPE Addr FROM VARCHAR(50)
GO

--CREATING SCHEMA
CREATE SCHEMA HumanResources
GO

CREATE SCHEMA Services
GO

CREATE SCHEMA Member
GO

CREATE SCHEMA [Transaction]
GO


---CREATING StaffDetails TABLE
CREATE TABLE StaffDetails(
StaffID int IDENTITY(1,1),
Branch_ID AS StaffID + 100 UNIQUE ,
FisrtName NAMES NOT NULL,
LastName NAMES NOT NULL,
Designation NAMES NOT NULL,
Address Addr NOT NULL,
Phone_Num Numb NOT NULL
)
GO

-----TRANSFERRING  TABLE INTO SCHEMA
ALTER SCHEMA HumanResources TRANSFER StaffDetails
Go

-----ADDING PRIMARY KEY
ALTER TABLE HumanResources.StaffDetails 
ADD CONSTRAint PPK PRIMARY KEY (StaffID)
GO


---CREATING RULE FOR PHONE NUMBER PATTERN
CREATE RULE Number AS @Numb LIKE 
'[0][789][01]' + Replicate ('[0-9]',8)
or @numb like '[+][2][3][4][789][01]' + Replicate ('[0-9]',8)
Go

exec sp_bindrule 'number','HumanResources.StaffDetails.phone_num'
GO


----inserting into staffdetails
INSERT HumanResources.StaffDetails VALUES ('Mr','Ibrahim','Tutor','12, ikola command ipaja','09053428766')
INSERT HumanResources.StaffDetails VALUES ('Eniola','gazel','cleaner','43, ikeja awolowo road','+2349053428766')
INSERT HumanResources.StaffDetails VALUES ('Iyiola','Tera','Tutor','53, ikeja awolowo road','+2349087428766')
INSERT HumanResources.StaffDetails VALUES ('Juwon','Makaveli','Assistance','03,Obafemi Awolowo road','+2349053487566')
GO

----inserting into staffdetails with errors
/*INSERT HumanResources.StaffDetails VALUES ('Mr','Ibrahim','Tutor','12, ikola command ipaja','08253428766')
INSERT HumanResources.StaffDetails VALUES ('Eniola','gazel','cleaner','43, ikeja awolowo road','+2339053428766')
INSERT HumanResources.StaffDetails VALUES ('Iyiola','Tera','Tutor','53, ikeja awolowo road','+234908742876656')
INSERT HumanResources.StaffDetails VALUES ('Juwon','Makaveli','Assistance','03,Obafemi Awolowo road','080905348756F')
GO */


SELECT * FROM HumanResources.StaffDetails
GO


---CREATING MembershipDetails TABLES
CREATE TABLE MembershipDetails(
PlanID int IDENTITY(1,1),
PlanType NAMES CONSTRAINT PT CHECK(PlanType IN('Premium','Standard','Guest')),
Fee money
)
GO
-----TRANSFERRING  TABLE INTO SCHEMA
ALTER SCHEMA Services TRANSFER MembershipDetails
Go

INSERT Services.MembershipDetails 
values('Premium',15000),('Standard',10000),('Guest',5000)
GO


ALTER TABLE Services.MembershipDetails 
ADD CONSTRAint PPK PRIMARY KEY (PlanID)
GO


----CREATING PLANDETAILS
CREATE TABLE PlanDetails(
FacilityID int IDENTITY(100,5),
PlanID int FOREIGN KEY REFERENCES Services.MembershipDetails(PlanID) ,
PLAN_DETAILS NAMES  CONSTRAINT PD CHECK(PLAN_DETAILS IN ('Sauna/Steam Baths','Yoga Classes','Aerobic Classes','Olympic-size pool'))
)
GO

-----TRANSFERRING  TABLE INTO SCHEMA
ALTER SCHEMA Services TRANSFER PlanDetails
Go

ALTER TABLE Services.PlanDetails ADD CONSTRAINT PK3 PRIMARY KEY(FacilityID) 
GO

INSERT INTO Services.PlanDetails VALUES (1,'Sauna/Steam Baths')
INSERT INTO Services.PlanDetails VALUES (2,'Yoga Classes')
INSERT INTO Services.PlanDetails VALUES (3,'Olympic-size pool')
INSERT INTO Services.PlanDetails VALUES (3,'Aerobic Classes')
GO
SELECT * FROM Services.PlanDetails
GO


---CREATING MEMBERDETAILS TABLES

CREATE TABLE MemberDetails(
MemberID int IDENTITY(1,1),
FirstName NAMES NOT NULL,
LastName NAMES NOT NULL,
Gender Gend CONSTRAint GendK CHECK(Gender IN('Male','Female')) NOT NULL,
Address Addr NOT NULL,
Phone_Numb Numb NOT NULL,
PlanID int FOREIGN KEY REFERENCES Services.MembershipDetails(PlanID)
)
GO

ALTER SCHEMA Member TRANSFER MemberDetails
GO

ALTER TABLE Member.MemberDetails 
ADD CONSTRAint SKZ PRIMARY KEY (MemberID)
GO

exec sp_bindrule 'number','Member.MemberDetails.phone_numb'
GO

INSERT INTO  Member.MemberDetails VALUES ('Adigun','Shola','Male','45,RESIDENRIAL Str','09098754321',1)
INSERT INTO  Member.MemberDetails VALUES ('Adegun','Tola','Female','40,REPRO Str','+2349098094321',3)
INSERT INTO  Member.MemberDetails VALUES ('lawson','olanrewaju','Male','45,RESIDENRIAL Street','09098754321',1)
INSERT INTO  Member.MemberDetails VALUES ('Sofie','daniel','Female','40, Niit Street','+2349098094321',3)
INSERT INTO  Member.MemberDetails VALUES ('Ben','John','Female','49, lagos Street','+2349098094321',2)
GO


--inserting with errors
/*INSERT INTO  Member.MemberDetails VALUES ('Adigun','Shola','hermophrodite','45,RESIDENRIAL Str','09098754321',1)
INSERT INTO  Member.MemberDetails VALUES ('Adegun','Tola','shemale','40,REPRO Str','+2349098094321',1)
INSERT INTO  Member.MemberDetails VALUES ('lawson','olanrewaju','Male','45,RESIDENRIAL Street','09098754321',4)
GO*/


SELECT * FROM Member.MemberDetails
GO


---CREATING TABLE REVENUE
CREATE Table Revenue(
PaymentID int IDENTITY(1,1) PRIMARY KEY,
MemberID int FOREIGN KEY REFERENCES Member.MemberDetails(MemberID),
PaymentDate date CHECK(PaymentDate >= GetDATE()),
PaymentMethod NAMES CONSTRAINT Payment CHECK (PaymentMethod IN('Cash','Cheque','Credit_Card')),
CC_Numb varchar(16) DEFAULT NULL,
CC_Name NAMES DEFAULT NULL,
Check_Numb varchar(10) DEFAULT NULL,
PaymentStatus NAMES CONSTRAINT PayST CHECK(PaymentStatus IN ('Paid','Pending')),
Amount money,
Balance money
)
GO

-----TRANSFERRING  TABLE INTO SCHEMA
ALTER SCHEMA [Transaction] TRANSFER Revenue
Go


---CREATING RULE FOR CC AND CHECK
CREATE RULE Cc_numb AS @cc_numb LIKE '[5]' + replicate('[0-9]',15)
Go
exec sp_bindrule 'cc_numb','[Transaction].Revenue.cc_numb'
GO
CREATE RULE check_numb AS @check_numb LIKE replicate('[0-9]',10)
Go
exec sp_bindrule 'check_numb','[Transaction].Revenue.check_numb'
GO


-----Creating Store procedure for Credit Card
CREATE PROC Credit_Card_Payment @MemberID int,
@PaymentDate date,
@CC_numb varchar(16),@CC_Name NAMES,@Amount money
AS
BEGIN
INSERT [Transaction].Revenue (MemberID,PaymentDate,
CC_Numb,CC_Name,Amount) VALUES
(@MemberID,@PaymentDate,@CC_Numb,@CC_Name,@Amount)

UPDATE [Transaction].Revenue SET PaymentMethod = 'Credit_Card' 
WHERE CC_Numb IS NOT NULL

END
GO

-----Creating Store procedure for cheque
CREATE PROC Cheque_Payment @MemberID int,@PaymentDate date,
@Check_Numb varchar(10),@Amount money
AS
BEGIN
INSERT [Transaction].Revenue (MemberID,PaymentDate,Check_Numb,Amount) VALUES
(@MemberID,@PaymentDate,@Check_Numb,@Amount)

UPDATE [Transaction].Revenue SET PaymentMethod = 'Cheque'
WHERE Check_Numb IS NOT NULL

END
GO


-----Creating Store procedure for cash
CREATE PROC Cash_Payment @MemberID int,@PaymentDate date,@Amount money
AS
BEGIN
INSERT [Transaction].Revenue (MemberID,PaymentDate,Amount) VALUES
(@MemberID,@PaymentDate,@Amount)

UPDATE [Transaction].Revenue SET PaymentMethod = 'Cash' 
WHERE CC_Numb IS NULL and CC_Name is null and Check_Numb is null
END
GO


CREATE TRIGGER tr_Revenue ON [Transaction].Revenue AFTER INSERT AS 
BEGIN

	DECLARE @PaymentID int, @Count int, @MemberID int, 
		@Fee money, @Amount money, @Balance money, @Due money

	SELECT @PaymentID = PaymentID FROM inserted
	SELECT @MemberID = MemberID FROM inserted
	SELECT @Amount = Amount FROM inserted

	--FETCHING FEE FROM MEMBERSHIPDETAILS
	SELECT @Fee = (SELECT Top 1 Fee from Services.MembershipDetails msd JOIN Member.MemberDetails md
	ON msd.PlanID = md.PlanID JOIN  [Transaction].Revenue rv ON rv.MemberID = md.MemberID
	WHERE md.MemberID = @MemberID)

	--COUNTING TO KNOW IF A MEMBER HAS MADE A PAYMENT BEFORE
	SELECT @Count = COUNT(*) FROM Revenue WHERE MemberID = @MemberID

	IF @Count > 1
	BEGIN
		DECLARE @Paid money
		SELECT @Paid = SUM(Amount) FROM Revenue WHERE MemberID = @MemberID
		SELECT @Paid = @Paid - @Amount
		SELECT @Due = @Fee - @Paid
	END
	ELSE 
	BEGIN
		SELECT @Due = @Fee
	END

	IF @Amount > @Due
	BEGIN
		PRINT 'Excess payment not allowed...'
		PRINT 'Amount Due: ' + CAST(@Due as varchar(25))
		ROLLBACK
	END
	ELSE
	BEGIN
		SELECT @Balance = @Due - @Amount
		UPDATE Revenue SET Balance = @Balance WHERE PaymentID = @PaymentID
		PRINT 'BALANCE REMAINING IS: ' + CAST(@BALANCE as varchar(25))
	END
	
	UPDATE Revenue SET PaymentStatus = 'Pending' WHERE Balance > 0
	UPDATE Revenue SET PaymentStatus = 'Paid' WHERE Balance = 0
	
END
GO 


--Inserting into CRESIT CARD and CASH and CHEQUE PAYMENT

Credit_Card_Payment 3,'20220727',5433345354442343,'Kazeem Cumrade',2200
GO

Cash_Payment 3,'20220727',2800
GO

Cheque_Payment 2, '20220727',5566545454,100
GO

SELECT * FROM [Transaction].Revenue
GO

--truncate table [Transaction].Revenue
--GO
--------CREATING TABLES
CREATE TABLE Booking( 
StaffID int FOREIGN KEY REFERENCES HumanResources.StaffDetails(StaffID),
MemberID int FOREIGN KEY REFERENCES Member.MemberDetails(MemberID),
PlanID int FOREIGN KEY REFERENCES Services.MembershipDetails(PlanID),
FacilityID int FOREIGN KEY REFERENCES Services.PlanDetails(FacilityID),
Max_Numb int DEFAULT 50 CHECK(Max_Numb = 50),
Actual_Numb int CONSTRAINT Acutual_Numb CHECK (Actual_Numb <= 50),
Booking_Status NAMES DEFAULT 'Available' CONSTRAINT Booking_Sta CHECK(Booking_Status IN('Booked','Available'))
)
go

-----TRANSFERRING  TABLE INTO SCHEMA
ALTER SCHEMA HumanResources TRANSFER Booking
Go


CREATE TRIGGER HumanResources.BOOKING_T ON HumanResources.Booking INSTEAD OF INSERT AS
BEGIN
  DECLARE @Max_Numb int,@Actual_Numb int,@Booking_Status NAMES,
  @StaffID int, @MemberID int, @PlanID int, @FacilityID int, @Count int


  SELECT @Max_Numb = Max_Numb FROM inserted
  SELECT @Actual_Numb = Actual_Numb FROM inserted
  SELECT @Booking_Status = Booking_Status FROM inserted
  SELECT @StaffID = staffid FROM inserted
  SELECT @MemberID = MemberID FROM inserted
  SELECT @PlanID = PlanID FROM inserted
  SELECT @FacilityID = FacilityId FROM inserted

  INSERT HumanResources.Booking (StaffID,MemberID,PlanID,FacilityID,Max_Numb,Actual_Numb)
  Values (@staffid,@MemberID,@PlanID,@FacilityID, @Max_Numb,@Actual_Numb)

 SELECT @Count = COUNT(*) FROM HumanResources.Booking WHERE MemberID = @MemberID 
 


IF @Count > 1
BEGIN
  IF EXISTS (SELECT MemberID FROM HumanResources.Booking WHERE FacilityID = @FacilityID) BEGIN
     PRINT'A MEMEBER CANNOT PAY FOR THE SAME FACILITY TWICE!!'
	 ROLLBACK

  END
    
END

 IF @Actual_Numb < @Max_Numb BEGIN
     
	    PRINT 'Actual Number IS LESS THAN 50...IT IS AVAILABLE!!'
		UPDATE HumanResources.Booking
		SET Booking_Status = 'Available'
		WHERE Actual_Numb < 50

	 END

  ELSE IF @Actual_Numb = @Max_Numb BEGIN
    		PRINT 'Actual Number IS 50!... IT IS BOOKED!!'
			UPDATE HumanResources.Booking
			SET Booking_Status = 'Booked'
			WHERE Actual_Numb = 50 
  END

END
GO

INSERT HumanResources.Booking (StaffID,MemberID,PlanID,FacilityID,Max_Numb,Actual_Numb)
Values (1,1,1,100,50,40)
INSERT HumanResources.Booking (StaffID,MemberID,PlanID,FacilityID,Max_Numb,Actual_Numb)
Values (2,2,2,100,50,40)
GO

select * from HumanResources.Booking
GO

--select FacilityID from HumanResources.Booking

--SELECT * FROM HumanResources.Booking HB INNER JOIN Services.PlanDetails SP ON SP.FacilityID =HB.FacilityID
--INSERT HumanResources.Booking VALUES (1,1,1,100,50,49,'available') 

/*UPDATE HumanResources.Booking
  SET Booking_Status = 'Available'
  WHERE Actual_Numb < 50

  UPDATE HumanResources.Booking
  SET Booking_Status = 'Booked'
  WHERE Actual_Numb >= 50
  */

--TRUNCATE TABLE HumanResources.Booking

--CREATING FEEDBACK TABLE
CREATE TABLE FEEDBACK(
REFID int IDENTITY (1,1),
STAFFID int FOREIGN KEY REFERENCES HumanResources.StaffDetails(StaffID),
MEMBERID int FOREIGN KEY REFERENCES Member.MemberDetails(MemberID),
FEEDBACK_TYPE NAMES CHECK(FEEDBACK_TYPE IN('Complaint','Suggestion','Appreciation'))
)
GO

-----TRANSFERRING  TABLE INTO SCHEMA
ALTER SCHEMA HumanResources TRANSFER FEEDBACK
Go

INSERT INTO HumanResources.FEEDBACK VALUES (1,1,'Complaint')
INSERT INTO HumanResources.FEEDBACK VALUES (2,2,'Suggestion')
INSERT INTO HumanResources.FEEDBACK VALUES (3,3,'Appreciation')
INSERT INTO HumanResources.FEEDBACK VALUES (4,4,'Complaint')
GO


CREATE TABLE FollowUp(
StaffID int FOREIGN KEY REFERENCES HumanResources.StaffDetails(StaffID),
Pros_MemberID int IDENTITY(1,1), 
Branch_ID int,
Pros_Fname NAMES not null,
Pros_Lname NAMES not null,
Phone_Numb Numb not null,
Visit_Date DATE
)
GO

-----TRANSFERRING  TABLE INTO SCHEMA
ALTER SCHEMA HumanResources TRANSFER FollowUp
Go

CREATE TRIGGER Bran ON HumanResources.FollowUp FOR INSERT
AS
BEGIN
Declare @branchid int
Select @branchid = Branch_ID from inserted

IF not exists (select Branch_ID from HumanResources.StaffDetails where Branch_ID = @branchid)
  BEGIN
  Print 'Foreign key error'
  Rollback
  END
END

GO

INSERT INTO HumanResources.FollowUp VALUES(1,101,'lawson','olanrewaju','09098754321','20220719')
INSERT INTO HumanResources.FollowUp VALUES(2,102,'Sofie','daniel','+2349098094321','20220719')
INSERT INTO  HumanResources.FollowUp VALUES (2,103,'Adigun','Shola','09098754321','20220820')
INSERT INTO  HumanResources.FollowUp VALUES (3,104,'Adegun','Tola','+2349098094321','20220721')
GO


SELECT * FROM HumanResources.FollowUp
GO

----CREATING INDEXES
--CREATE CLUSTERED INDEX IX_MonthlyDetaiLs ON [Transaction].Revenue(PaymentDate)
--GO

SELECT PaymentDate FROM [Transaction].Revenue WHERE DATEPART(MM, PaymentDate) = DATEPART(MM, GETDATE())
GO

CREATE CLUSTERED INDEX IX_FeedBacks ON HumanResources.FEEDBACK(FEEDBACK_TYPE)
GO

SELECT FEEDBACK_TYPE FROM HumanResources.FEEDBACK WHERE FEEDBACK_TYPE = 'Complaint' OR FEEDBACK_TYPE = 'Suggestion'
GO

---CREATING FUNCTIONS
CREATE FUNCTION PaymentStatus (@PaymentStatus NAMES)
RETURNS TABLE
AS
  RETURN(
    SELECT * FROM [Transaction].Revenue WHERE PaymentStatus = @PaymentStatus   
  )
  GO
  SELECT * FROM dbo.PaymentStatus('Pending')
  GO
---------------
SELECT PlanType,Fee,PLAN_DETAILS INTO AboutFacility FROM Services.MembershipDetails msd JOIN Services.PlanDetails pd ON
msd.PlanID = pd.PlanID
GO

SELECT * FROM AboutFacility
GO

CREATE FUNCTION MemberPerMonth(@Month int)
RETURNS @Table TABLE
(FirstName NAMES not null,
 LastName NAMES,
 Branch_ID int,
 VisitationDate date)
 AS BEGIN
    INSERT @Table
	SELECT Pros_Fname,Pros_Lname,Branch_ID,Visit_Date FROM HumanResources.FollowUp WHERE DATEPART(MM, Visit_Date) = @Month
	RETURN
 END
 GO

 SELECT * FROM MemberPerMonth(7)
 GO

 -------------------------- B