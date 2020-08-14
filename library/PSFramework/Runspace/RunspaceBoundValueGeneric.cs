using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
        public new Dictionary<Guid, T> Values = new Dictionary<Guid, T>();

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
