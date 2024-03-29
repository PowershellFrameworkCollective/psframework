﻿using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Wrapper class that offers the tools to make Values runspace specific
    /// </summary>
    public class RunspaceBoundValue : IDisposable
    {
        /// <summary>
        /// Whether the default value should be offered when asking from a runspace without custom settings
        /// </summary>
        public bool OfferDefaultValue = true;

        /// <summary>
        /// The default value to offer
        /// </summary>
        public object DefaultValue;

        /// <summary>
        /// The values available on a "per runspace" basis
        /// </summary>
        public ConcurrentDictionary<Guid, object> Values = new ConcurrentDictionary<Guid, object>();

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

        /// <summary>
        /// Removes all value entries whose corresponding Runspace has been destroyed
        /// </summary>
        public virtual void PurgeExpired()
        {
            // Store IDs first, so parallel access is not an issue and a new value gets accidentally discarded
            Guid[] IDs = Values.Keys.ToList().ToArray();
            ICollection<System.Management.Automation.Runspaces.Runspace> runspaces = UtilityHost.GetRunspaces();
            IEnumerable<Guid> runspaceIDs = (IEnumerable<Guid>)runspaces.Select(o => o.InstanceId);

            object temp;
            foreach (Guid ID in IDs)
                if (!runspaceIDs.Contains(ID))
                    Values.TryRemove(ID, out temp);
        }

        /// <summary>
        /// Destruction logic, eliminating all data stored in the object.
        /// Since handles to this object are automatically stored and maintained, it is impossible to otherwise guarantee releasing the object's data for the GC.
        /// </summary>
        public void Dispose()
        {
            Values = new ConcurrentDictionary<Guid, object>();
            DefaultValue = null;
            RunspaceHost._RunspaceBoundValues.Remove(this);
        }

        /// <summary>
        /// Create an empty runspace bound value object
        /// </summary>
        public RunspaceBoundValue()
            : this(null, true)
        {

        }

        /// <summary>
        /// Create a runspace bound value object with its initial value
        /// </summary>
        /// <param name="Value">The object to set as the initial value</param>
        public RunspaceBoundValue(object Value)
            : this(Value, true)
        {

        }

        /// <summary>
        /// Create a runspace bound value object with its initial value
        /// </summary>
        /// <param name="Value">The object to set as the initial value</param>
        /// <param name="OfferDefaultValue">Whether the initial / default value should be offered when accessed from runspaces that do not have a runspace-local value</param>
        public RunspaceBoundValue(object Value, bool OfferDefaultValue)
        {
            this.Value = Value;
            this.OfferDefaultValue = OfferDefaultValue;

            // Add to central list of runspacebound values
            RunspaceHost._RunspaceBoundValues.Add(this);
        }
    }
}
