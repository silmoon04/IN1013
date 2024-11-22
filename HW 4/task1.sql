-- Drop the existing database if it exists and create a new one
DROP DATABASE IF EXISTS HealthFitnessDB;
CREATE DATABASE HealthFitnessDB;
USE HealthFitnessDB;

-- Drop tables in reverse order of dependencies
DROP TABLE IF EXISTS HeartRateZone;
DROP TABLE IF EXISTS HeartRateZoneDefinition;
DROP TABLE IF EXISTS Workout;
DROP TABLE IF EXISTS Sleep;
DROP TABLE IF EXISTS JournalEntry;
DROP TABLE IF EXISTS PhysiologicalCycle;
DROP TABLE IF EXISTS Sync;
DROP TABLE IF EXISTS Smartwatch;
DROP TABLE IF EXISTS SmartDevice;
DROP TABLE IF EXISTS User;

-- Create User table with recursive relationship for Manager
CREATE TABLE User (
    User_ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Date_of_Birth DATE NOT NULL,
    Gender VARCHAR(20) CHECK (Gender IN ('Male', 'Female', 'Non-Binary', 'Other', 'Prefer not to say')),
    Weight_Kg DECIMAL(5,2) CHECK (Weight_Kg BETWEEN 30 AND 300),
    Height_Cm DECIMAL(5,2) CHECK (Height_Cm BETWEEN 100 AND 250),
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone_Number VARCHAR(15) UNIQUE,
    Manager_ID INT,
    FOREIGN KEY (Manager_ID) REFERENCES User(User_ID) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Create SmartDevice table without Device_Type to avoid redundancy
CREATE TABLE SmartDevice (
    Device_ID INT AUTO_INCREMENT PRIMARY KEY,
    Model VARCHAR(50) NOT NULL,
    Firmware_Version VARCHAR(20) NOT NULL,
    User_ID INT NOT NULL,
    FOREIGN KEY (User_ID) REFERENCES User(User_ID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Create Smartwatch table as a subtype of SmartDevice
CREATE TABLE Smartwatch (
    Device_ID INT PRIMARY KEY,
    Battery_Life_Hours INT NOT NULL CHECK (Battery_Life_Hours >= 0),
    Water_Resistance_Rating VARCHAR(20) NOT NULL,
    FOREIGN KEY (Device_ID) REFERENCES SmartDevice(Device_ID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Create PhysiologicalCycle table with composite primary key (User_ID, Date)
CREATE TABLE PhysiologicalCycle (
    User_ID INT NOT NULL,
    Date DATE NOT NULL,
    Recovery_Score_Percent DECIMAL(5,2) CHECK (Recovery_Score_Percent BETWEEN 0 AND 100),
    Resting_Heart_Rate_BPM INT CHECK (Resting_Heart_Rate_BPM > 0),
    Heart_Rate_Variability_MS DECIMAL(5,2) CHECK (Heart_Rate_Variability_MS >= 0),
    Skin_Temp_Celsius DECIMAL(4,2) NOT NULL,
    Blood_Oxygen_Percent DECIMAL(4,2) CHECK (Blood_Oxygen_Percent BETWEEN 0 AND 100),
    Day_Strain DECIMAL(5,2) CHECK (Day_Strain >= 0),
    PRIMARY KEY (User_ID, Date),
    FOREIGN KEY (User_ID) REFERENCES User(User_ID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Create JournalEntry table with composite primary key (User_ID, Date)
CREATE TABLE JournalEntry (
    User_ID INT NOT NULL,
    Date DATE NOT NULL,
    Question_Text VARCHAR(255) NOT NULL,
    Answered_Yes BOOLEAN NOT NULL,
    Notes TEXT,
    PRIMARY KEY (User_ID, Date),
    FOREIGN KEY (User_ID, Date) REFERENCES PhysiologicalCycle(User_ID, Date) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Create Sleep table without cross-column CHECK constraints
CREATE TABLE Sleep (
    Sleep_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT NOT NULL,
    Date DATE NOT NULL,
    Start_Time DATETIME NOT NULL,
    End_Time DATETIME NOT NULL,
    Total_Sleep_Time_Min DECIMAL(5,2) CHECK (Total_Sleep_Time_Min >= 0) NOT NULL,
    Light_Sleep_Min DECIMAL(5,2) CHECK (Light_Sleep_Min >= 0) NOT NULL,
    Deep_Sleep_Min DECIMAL(5,2) CHECK (Deep_Sleep_Min >= 0) NOT NULL,
    REM_Sleep_Min DECIMAL(5,2) CHECK (REM_Sleep_Min >= 0) NOT NULL,
    Awake_Min DECIMAL(5,2) CHECK (Awake_Min >= 0) NOT NULL,
    FOREIGN KEY (User_ID, Date) REFERENCES PhysiologicalCycle(User_ID, Date) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Create Workout table without cross-column CHECK constraints
CREATE TABLE Workout (
    Workout_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT NOT NULL,
    Date DATE NOT NULL,
    Start_Time DATETIME NOT NULL,
    End_Time DATETIME NOT NULL,
    Activity_Name VARCHAR(50) NOT NULL,
    Activity_Strain DECIMAL(5,2) CHECK (Activity_Strain >= 0) NOT NULL,
    Energy_Burned_Cal DECIMAL(6,2) CHECK (Energy_Burned_Cal >= 0) NOT NULL,
    Max_HR_BPM INT CHECK (Max_HR_BPM >= 0) NOT NULL,
    Average_HR_BPM INT CHECK (Average_HR_BPM >= 0) NOT NULL,
    Distance_Meters DECIMAL(7,2) CHECK (Distance_Meters >= 0),
    Altitude_Gain_Meters DECIMAL(6,2) CHECK (Altitude_Gain_Meters >= 0),
    Altitude_Change_Meters DECIMAL(6,2),
    FOREIGN KEY (User_ID, Date) REFERENCES PhysiologicalCycle(User_ID, Date) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Create HeartRateZoneDefinition table to standardize heart rate zones
CREATE TABLE HeartRateZoneDefinition (
    Zone_ID INT AUTO_INCREMENT PRIMARY KEY,
    Zone_Name VARCHAR(20) NOT NULL,
    Min_HR_Percent DECIMAL(5,2) NOT NULL CHECK (Min_HR_Percent BETWEEN 0 AND 100),
    Max_HR_Percent DECIMAL(5,2) NOT NULL CHECK (Max_HR_Percent BETWEEN 0 AND 100),
    CHECK (Min_HR_Percent < Max_HR_Percent)
) ENGINE=InnoDB;

-- Insert standard heart rate zones into HeartRateZoneDefinition
INSERT INTO HeartRateZoneDefinition (Zone_Name, Min_HR_Percent, Max_HR_Percent) VALUES
('Zone 1', 50.00, 60.00),
('Zone 2', 60.01, 70.00),
('Zone 3', 70.01, 80.00),
('Zone 4', 80.01, 90.00),
('Zone 5', 90.01, 100.00);

-- Create HeartRateZone table as an associative entity between Workout and HeartRateZoneDefinition
CREATE TABLE HeartRateZone (
    Workout_ID INT NOT NULL,
    Zone_ID INT NOT NULL,
    Duration_Minutes DECIMAL(5,2) CHECK (Duration_Minutes >= 0) NOT NULL,
    PRIMARY KEY (Workout_ID, Zone_ID),
    FOREIGN KEY (Workout_ID) REFERENCES Workout(Workout_ID) ON DELETE CASCADE,
    FOREIGN KEY (Zone_ID) REFERENCES HeartRateZoneDefinition(Zone_ID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Create Sync table to record synchronization events between users and devices
CREATE TABLE Sync (
    Sync_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT NOT NULL,
    Device_ID INT NOT NULL,
    Sync_Timestamp DATETIME NOT NULL,
    FOREIGN KEY (User_ID) REFERENCES User(User_ID) ON DELETE CASCADE,
    FOREIGN KEY (Device_ID) REFERENCES SmartDevice(Device_ID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Create indexes for faster querying on frequently accessed columns
CREATE INDEX idx_user_email ON User(Email);
CREATE INDEX idx_user_phone ON User(Phone_Number);
CREATE INDEX idx_physcycle_user_date ON PhysiologicalCycle(User_ID, Date);
CREATE INDEX idx_sleep_user_date ON Sleep(User_ID, Date);
CREATE INDEX idx_workout_user_date ON Workout(User_ID, Date);
CREATE INDEX idx_sync_device_user ON Sync(Device_ID, User_ID);

-- Create triggers to enforce that the sum of HeartRateZone durations equals workout duration
DELIMITER //

CREATE TRIGGER trg_HRZone_Duration_Sum
BEFORE INSERT ON HeartRateZone
FOR EACH ROW
BEGIN
    DECLARE total_duration DECIMAL(10,2);
    DECLARE workout_duration DECIMAL(10,2);

    SELECT TIMESTAMPDIFF(MINUTE, Start_Time, End_Time) INTO workout_duration
    FROM Workout
    WHERE Workout_ID = NEW.Workout_ID;

    SELECT IFNULL(SUM(Duration_Minutes), 0) INTO total_duration
    FROM HeartRateZone
    WHERE Workout_ID = NEW.Workout_ID;

    IF (total_duration + NEW.Duration_Minutes) > workout_duration THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total Heart Rate Zone Duration exceeds Workout Duration.';
    END IF;
END;
//

CREATE TRIGGER trg_HRZone_Duration_Sum_Update
BEFORE UPDATE ON HeartRateZone
FOR EACH ROW
BEGIN
    DECLARE total_duration DECIMAL(10,2);
    DECLARE workout_duration DECIMAL(10,2);

    SELECT TIMESTAMPDIFF(MINUTE, Start_Time, End_Time) INTO workout_duration
    FROM Workout
    WHERE Workout_ID = NEW.Workout_ID;

    SELECT IFNULL(SUM(Duration_Minutes), 0) INTO total_duration
    FROM HeartRateZone
    WHERE Workout_ID = NEW.Workout_ID AND Zone_ID != OLD.Zone_ID;

    IF (total_duration + NEW.Duration_Minutes) > workout_duration THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total Heart Rate Zone Duration exceeds Workout Duration.';
    END IF;
END;
//

-- Create triggers to enforce that the sum of Sleep stages equals Total_Sleep_Time_Min and End_Time > Start_Time
CREATE TRIGGER trg_Sleep_Stages_Sum
BEFORE INSERT ON Sleep
FOR EACH ROW
BEGIN
    IF (NEW.Total_Sleep_Time_Min != (NEW.Light_Sleep_Min + NEW.Deep_Sleep_Min + NEW.REM_Sleep_Min + NEW.Awake_Min)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total_Sleep_Time_Min must equal the sum of all sleep stages.';
    END IF;

    IF (NEW.End_Time <= NEW.Start_Time) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'End_Time must be after Start_Time.';
    END IF;
END;
//

CREATE TRIGGER trg_Sleep_Stages_Sum_Update
BEFORE UPDATE ON Sleep
FOR EACH ROW
BEGIN
    IF (NEW.Total_Sleep_Time_Min != (NEW.Light_Sleep_Min + NEW.Deep_Sleep_Min + NEW.REM_Sleep_Min + NEW.Awake_Min)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total_Sleep_Time_Min must equal the sum of all sleep stages.';
    END IF;

    IF (NEW.End_Time <= NEW.Start_Time) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'End_Time must be after Start_Time.';
    END IF;
END;
//

DELIMITER ;
