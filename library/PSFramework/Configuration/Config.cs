using PSFramework.PSFCore;
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
                if (Value == null)
                    return null;
                return Value.GetType().FullName;
            }
            set { }
        }

        /// <summary>
        /// The value stored in the configuration element
        /// </summary>
        public object Value
        {
            get
            {
                if (_Value == null)
                    return null;
                return _Value.Value;
            }
            set
            {
                if (_PolicyEnforced)
                    return;
                if (_Value == null)
                    _Value = new ConfigurationValue(value);
                else
                    _Value.Value = value;
                if (Initialized)
                    _Unchanged = false;
            }
        }
        private ConfigurationValue _Value;

        /// <summary>
        /// The value stored in the configuration element, but without deserializing objects.
        /// </summary>
        public object SafeValue
        {
            get { return _Value.SafeValue; }
            set { }
        }

        /// <summary>
        /// Whether the value of the configuration setting has been changed since its initialization.
        /// </summary>
        public bool Unchanged
        {
            get { return _Unchanged; }
            set { }
        }
        private bool _Unchanged = true;

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
        public bool Initialized
        {
            get { return _Initialized; }
            set
            {
                if (!_Initialized)
                    _Initialized = value;
            }
        }
        private bool _Initialized;

        /// <summary>
        /// Whether this setting was set by policy
        /// </summary>
        public bool PolicySet = false;

        /// <summary>
        /// Whether this setting was set by policy and forbids changes to the configuration.
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

        /// <summary>
        /// Enabling this causes export to json to use simple json serialization for data transmission.
        /// This is suitable for simple data that is not sensitive to conversion losses.
        /// Simple export leads to exports more easily readable to the human eye.
        /// </summary>
        public bool SimpleExport = false;

        /// <summary>
        /// Whether this setting should be exported to a module specific file when exporting to json by modulename.
        /// </summary>
        public bool ModuleExport = false;

        /// <summary>
        /// The finalized value to put into the registry value when using policy to set this setting.
        /// Deprecated property.
        /// </summary>
        public string RegistryData
        {
            get
            {
                return _Value.TypeQualifiedPersistedValue;
            }
            set { }
        }

        /// <summary>
        /// Applies the persisted value to the configuration item.
        /// This method should only be called by PSFramework internals
        /// </summary>
        /// <param name="Type">The type of data being specified</param>
        /// <param name="ValueString">The value string to register</param>
        [PsfInternal(Description = "Only intended for use within internal configuration import mechanics. Some are in script, requiring public accessibility.")]
        public void SetPersistedValue(ConfigurationValueType Type, string ValueString)
        {
            if (_PolicyEnforced)
                return;

            if (Type == ConfigurationValueType.Unknown)
            {
                int index = ValueString.IndexOf(':');
                if (index < 1)
                    throw new ArgumentException(String.Format("Bad persisted configuration value! Could not find type qualifier on {0}", ValueString));
                Type = (ConfigurationValueType)Enum.Parse(typeof(ConfigurationValueType), ValueString.Substring(0, index), true);
                ValueString = ValueString.Substring(index + 1);
            }

            if (_Value == null)
                _Value = new ConfigurationValue(ValueString, Type);
            else
            {
                _Value.PersistedType = Type;
                _Value.PersistedValue = ValueString;
            }
        }
    }
}
