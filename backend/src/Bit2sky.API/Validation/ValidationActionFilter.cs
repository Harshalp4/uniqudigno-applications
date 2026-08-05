using Bit2sky.Shared;
using FluentValidation;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Bit2sky.API.Validation;

// Runs any registered FluentValidation validator for each action argument and
// throws ValidationAppException (→ 400 envelope) on failure (Section 4B).
public class ValidationActionFilter : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        foreach (var arg in context.ActionArguments.Values)
        {
            if (arg is null) continue;
            var validatorType = typeof(IValidator<>).MakeGenericType(arg.GetType());
            if (context.HttpContext.RequestServices.GetService(validatorType) is not IValidator validator) continue;

            var result = await validator.ValidateAsync(new ValidationContext<object>(arg));
            if (!result.IsValid)
                throw new ValidationAppException(result.Errors
                    .Select(e => new ApiError { Field = e.PropertyName, Message = e.ErrorMessage }));
        }

        await next();
    }
}
