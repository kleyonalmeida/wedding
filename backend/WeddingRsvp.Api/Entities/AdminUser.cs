using System;
using Microsoft.AspNetCore.Identity;

namespace WeddingRsvp.Api.Entities;

public class AdminUser : IdentityUser<Guid>
{
    public bool MustChangePassword { get; set; } = true;
    public DateTimeOffset? CreatedAtUtc { get; set; } = DateTimeOffset.UtcNow;
}
