using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Enums
{
    public enum OrderStatus
    {
        PendingInTake,
        Accepted,
        Rejected,
        ReadyForCollection,
        Collected,
        AtFactory,
        ReadyForWashing,
        Washing,
        OnLaundryLine,
        IssueFlagged,
        Ironing,
        Packing,
        ReadyForCustomerCollection,
        OutForDelivery,
        Completed,
        Cancelled
    }
}
