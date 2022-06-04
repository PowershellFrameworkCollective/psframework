using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using PSFramework.Utility;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Generic implementation of RunspaceBoundValue
    /// </summary>
    /// <typeparam name="T">The type to use for wrapping</typeparam>
    public class RunspaceBoundValueGeneric<T> : RunspaceBoundValue
    {
        /// <summary>
        /// The default value to offer
        /// </summary>
        public new T DefaultValue;

        /// <summary>
        /// The values available on a "per runspace" basis
        /// </summary>
        public new ConcurrentDictionary<Guid, T> Values = new ConcurrentDictionary<Guid, T>();

        /// <summary>
        /// The value to offer or set, specific per runspace from which it is called
        /// </summary>
        public new T Value
        {
            get
            {
                if (Values.ContainsKey(System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId))
                    return Values[System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId];
                else if (OfferDefaultValue)
                    return DefaultValue;
                else
                    return _NullValue;
            }
            set
            {
                if (Values.Keys.Count == 0)
                    DefaultValue = value;
                Values[System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId] = value;
            }
        }
        #pragma warning disable 0649
        private readonly T _NullValue;
        #pragma warning restore 0649

        /// <summary>
        /// Removes all value entries whose corresponding Runspace has been destroyed
        /// </summary>
        public override void PurgeExpired()
        {
            // Store IDs first, so parallel access is not an issue and a new value gets accidentally discarded
            Guid[] IDs = Values.Keys.ToList().ToArray();
            ICollection<System.Management.Automation.Runspaces.Runspace> runspaces = UtilityHost.GetRunspaces();
            IEnumerable<Guid> runspaceIDs = (IEnumerable<Guid>)runspaces.Select(o => o.InstanceId);

            T temp;
            foreach (Guid ID in IDs)
                if (!runspaceIDs.Contains(ID))
                    Values.TryRemove(ID, out temp);
        }

        /// <summary>
        /// Create an empty runspace bound value object
        /// </summary>
        public RunspaceBoundValueGeneric()
        {
            this.OfferDefaultValue = true;
            // Add to central list of runspacebound values
            RunspaceHost._RunspaceBoundValues.Add(this);
        }

        /// <summary>
        /// Create a runspace bound value object with its initial value
        /// </summary>
        /// <param name="Value">The object to set as the initial value</param>
        public RunspaceBoundValueGeneric(T Value)
            : this(Value, true)
        {

        }

        /// <summary>
        /// Create a runspace bound value object with its initial value
        /// </summary>
        /// <param name="Value">The object to set as the initial value</param>
        /// <param name="OfferDefaultValue">Whether the initial / default value should be offered when accessed from runspaces that do not have a runspace-local value</param>
        public RunspaceBoundValueGeneric(T Value, bool OfferDefaultValue)
        {
            this.Value = Value;
            this.OfferDefaultValue = OfferDefaultValue;

            // Add to central list of runspacebound values
            RunspaceHost._RunspaceBoundValues.Add(this);
        }
    }
}
