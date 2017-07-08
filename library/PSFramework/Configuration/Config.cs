using System;
using System.Management.Automation;

namespace PSFramework.Configuration
{
    /// <summary>
    /// Configuration Manager as well as individual configuration object.
    /// </summary>
    [Serializable]
    public class Config
    {
        /// <summary>
        /// The Name of the setting
        /// </summary>
        public string Name;

        /// <summary>
        /// The full name of the configuration entry, comprised of both Module and Name.
        /// </summary>
        public string FullName
        {
            get { return Module + "." + Name; }
            set { }
        }

        /// <summary>
        /// The module of the setting. Helps being able to group configurations.
        /// </summary>
        public string Module;

        /// <summary>
        /// A description of the specific setting
        /// </summary>
        public string Description;

        /// <summary>
        /// The data type of the value stored in the configuration element.
        /// </summary>
        public string Type
        {
            get
            {
                try { return Value.GetType().FullName; }
                catch { return null; }
            }
            set { }
        }

        /// <summary>
        /// The value stored in the configuration element
        /// </summary>
        public Object Value;

        /// <summary>
        /// The handler script that is run whenever the configuration value is set.
        /// </summary>
        public ScriptBlock Handler;

        /// <summary>
        /// Validates the user input
        /// </summary>
        public ScriptBlock Validation;

        /// <summary>
        /// Setting this to true will cause the element to not be discovered unless using the '-Force' parameter on "Get-DbaConfig"
        /// </summary>
        public bool Hidden = false;

        /// <summary>
        /// Whether the setting has been initialized. This handles module imports and avoids modules overwriting settings when imported in multiple runspaces.
        /// </summary>
        public bool Initialized;

        /// <summary>
        /// Whether this setting was set by policy
        /// </summary>
        public bool PolicySet = false;

        /// <summary>
        /// Whether this setting was set by policy and forbids deletion.
        /// </summary>
        public bool PolicyEnforced
        {
            get { return _PolicyEnforced; }
            set
            {
                if (_PolicyEnforced == false) { _PolicyEnforced = value; }
            }
        }
        private bool _PolicyEnforced = false;
    }
}
