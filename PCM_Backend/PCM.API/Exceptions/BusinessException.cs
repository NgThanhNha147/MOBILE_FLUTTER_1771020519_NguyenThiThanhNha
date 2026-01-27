namespace PCM.API.Exceptions;

public class BusinessException : Exception
{
    public int StatusCode { get; }
    public string ErrorCode { get; }
    
    public BusinessException(int statusCode, string message, string errorCode = "") 
        : base(message)
    {
        StatusCode = statusCode;
        ErrorCode = errorCode;
    }
}

public class BookingConflictException : BusinessException
{
    public BookingConflictException(string message = "Time slot is already booked") 
        : base(409, message, "TIME_SLOT_CONFLICT") { }
}

public class InsufficientBalanceException : BusinessException
{
    public InsufficientBalanceException(decimal required, decimal available) 
        : base(400, $"Insufficient balance. Need {required:N0}đ, have {available:N0}đ", "INSUFFICIENT_BALANCE") { }
}

public class InvalidTimeException : BusinessException
{
    public InvalidTimeException(string message) 
        : base(422, message, "INVALID_TIME") { }
}

public class BookingNotFoundException : BusinessException
{
    public BookingNotFoundException(string message = "Booking not found") 
        : base(404, message, "BOOKING_NOT_FOUND") { }
}

public class CancelTooLateException : BusinessException
{
    public CancelTooLateException(string message = "Cannot cancel booking within 6 hours of start time") 
        : base(400, message, "CANCEL_TOO_LATE") { }
}
