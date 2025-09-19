-- Cập nhật database schema cho PasswordResetTokens với Code thay vì Token
-- Chạy script này trong SQL Server Management Studio

-- Xóa bảng cũ nếu tồn tại
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'PasswordResetTokens')
BEGIN
    DROP TABLE PasswordResetTokens;
END

-- Tạo bảng PasswordResetTokens mới với Code
CREATE TABLE PasswordResetTokens (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(255) NOT NULL,
    Code NVARCHAR(6) NOT NULL, -- 6-digit code
    ExpiresAt DATETIME2 NOT NULL,
    IsUsed BIT NOT NULL DEFAULT 0,
    IsVerified BIT NOT NULL DEFAULT 0, -- Đã verify code chưa
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);

-- Tạo index cho Email để tìm kiếm nhanh
CREATE INDEX IX_PasswordResetTokens_Email ON PasswordResetTokens(Email);

-- Tạo index cho Code để tìm kiếm nhanh
CREATE INDEX IX_PasswordResetTokens_Code ON PasswordResetTokens(Code);

-- Tạo index cho ExpiresAt để cleanup token hết hạn
CREATE INDEX IX_PasswordResetTokens_ExpiresAt ON PasswordResetTokens(ExpiresAt);

-- Tạo index composite cho Email + Code + IsUsed + IsVerified
CREATE INDEX IX_PasswordResetTokens_Email_Code_Status ON PasswordResetTokens(Email, Code, IsUsed, IsVerified);

-- Kiểm tra bảng đã tạo thành công
SELECT 'PasswordResetTokens table created successfully' as Status;

-- Kiểm tra cấu trúc bảng
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'PasswordResetTokens'
ORDER BY ORDINAL_POSITION;
