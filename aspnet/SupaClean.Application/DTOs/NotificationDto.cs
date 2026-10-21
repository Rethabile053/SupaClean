using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record NotificationDto(Guid NotificationId, string Title, string Message,
                               Guid? OrderId, bool IsRead, DateTime SentAt);
}
