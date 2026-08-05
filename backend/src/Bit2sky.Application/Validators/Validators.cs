using Bit2sky.Application.Abstractions;
using Bit2sky.Application.DTOs;
using FluentValidation;

namespace Bit2sky.Application.Validators;

// Input validation (Section 4B). All inputs validated before processing.
public class SendOtpRequestValidator : AbstractValidator<SendOtpRequest>
{
    public SendOtpRequestValidator()
        => RuleFor(x => x.Mobile).NotEmpty().Matches(@"^\+?[0-9]{10,15}$")
            .WithMessage("Invalid mobile number format.");
}

public class VerifyOtpRequestValidator : AbstractValidator<VerifyOtpRequest>
{
    public VerifyOtpRequestValidator()
    {
        RuleFor(x => x.SessionId).NotEmpty();
        RuleFor(x => x.Otp).NotEmpty().Matches(@"^[0-9]{6}$").WithMessage("OTP must be 6 digits.");
        RuleFor(x => x.DeviceInfo).NotEmpty().MaximumLength(512);
    }
}

public class UpdateMeRequestValidator : AbstractValidator<UpdateMeRequest>
{
    public UpdateMeRequestValidator()
    {
        RuleFor(x => x.Name).MaximumLength(150);
        RuleFor(x => x.Email).EmailAddress().When(x => !string.IsNullOrEmpty(x.Email));
        RuleFor(x => x.Mobile).Matches(@"^\+91[0-9]{10}$")
            .When(x => !string.IsNullOrEmpty(x.Mobile))
            .WithMessage("Mobile must be +91 followed by 10 digits.");
    }
}

public class AddCartItemRequestValidator : AbstractValidator<AddCartItemRequest>
{
    public AddCartItemRequestValidator()
        => RuleFor(x => x).Must(x => x.TestId.HasValue || x.PackageId.HasValue)
            .WithMessage("TestId or PackageId is required.");
}

public class FamilyMemberRequestValidator : AbstractValidator<FamilyMemberRequest>
{
    public FamilyMemberRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Relationship).NotEmpty().MaximumLength(50);
        // A family member is a patient: labs need age + sex to interpret results.
        RuleFor(x => x.Gender).NotNull().WithMessage("Gender is required.");
        RuleFor(x => x.DateOfBirth).NotNull().WithMessage("Date of birth is required.")
            .Must(d => d == null || d.Value <= DateOnly.FromDateTime(DateTime.UtcNow.Date))
            .WithMessage("Date of birth cannot be in the future.");
    }
}

public class AddressRequestValidator : AbstractValidator<AddressRequest>
{
    public AddressRequestValidator()
    {
        RuleFor(x => x.Line1).NotEmpty().MaximumLength(250);
        RuleFor(x => x.City).NotEmpty().MaximumLength(100);
        RuleFor(x => x.State).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Pincode).NotEmpty().Matches(@"^[0-9]{6}$").WithMessage("Invalid pincode.");
    }
}

public class CreateTicketRequestValidator : AbstractValidator<CreateTicketRequest>
{
    public CreateTicketRequestValidator()
    {
        RuleFor(x => x.Subject).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Message).NotEmpty().MaximumLength(4000);
    }
}
