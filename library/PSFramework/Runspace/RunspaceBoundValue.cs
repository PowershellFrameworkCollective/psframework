using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Wrapper class that offers the tools to make Values runspace specific
    /// </summary>
    public class RunspaceBoundValue
    {
        /// <summary>
        /// Whether the defautl value should be offered when asking from a runspace without custom settings
        /// </summary>
        public bool OfferDefaultValue = true;

        /// <summary>
        /// The default value to offer
        /// </summary>
        public object DefaultValue;

        /// <summary>
        /// The values available on a "per runspace" basis
        /// </summary>
        public Dictionary<Guid, object> Values = new Dictionary<Guid, object>();

        /// <summary>
        /// The value to offer or set, specific per runspace from which it is called
        /// </summary>
        public object Value
        {
            get
            {
                if (Values.ContainsKey(System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId))
                    return Values[System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId];
                else if (OfferDefaultValue)
                    return DefaultValue;
                else
                    return null;
            }
            set
            {
                if (Values.Keys.Count == 0)
                    DefaultValue = value;
                Values[System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId] = value;
            }
        }

        public void PurgeExpired()
        {
            System.Management.Automation.Runspaces.Runspace.GetRunspaces(null);
        }
    }
}
