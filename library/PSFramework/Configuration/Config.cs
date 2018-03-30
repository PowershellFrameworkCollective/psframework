using System;
using System.Collections.Generic;
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
        public Object Value
        {
            get { return _Value; }
            set
            {
                _Value = value;
                if (Initialized)
                    _Unchanged = false;
            }
        }
        private Object _Value;

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

        /// <summary>
        /// The finalized value to put into the registry value when using policy to set this setting.
        /// </summary>
        public string RegistryData
        {
            get
            {
                switch (Type)
                {
                    case "System.Object[]":
                        List<string> items = new List<string>();

                        foreach (object item in (object[])Value)
                        {
                            string temp = GetRegistryValue(item);
                            if (temp == "<type not supported>")
                                return temp;
                            items.Add(temp);
                        }

                        return String.Format("array:{0}", String.Join("þþþ", items));
                    default:
                        return GetRegistryValue(Value);
                }
            }
        }

        private static string GetRegistryValue(object Item)
        {
            if (Item == null)
                return "<type not supported>";

            switch (Item.GetType().FullName)
            {
                case "System.Boolean":
                    if ((bool)Item)
                        return "bool:true";
                    return "bool:false";
                case "System.Int16":
                    return String.Format("int:{0}", Item);
                case "System.Int32":
                    return String.Format("int:{0}", Item);
                case "System.Int64":
                    return String.Format("long:{0}", Item);
                case "System.UInt16":
                    return String.Format("int:{0}", Item);
                case "System.UInt32":
                    return String.Format("long:{0}", Item);
                case "System.UInt64":
                    return String.Format("long:{0}", Item);
                case "System.Double":
                    return String.Format("double:{0}", Item);
                case "System.String":
                    return String.Format("string:{0}", Item);
                case "System.TimeSpan":
                    return String.Format("timespan:{0}", ((TimeSpan)Item).Ticks);
                case "System.DateTime":
                    return String.Format("datetime:{0}", ((DateTime)Item).Ticks);
                case "System.ConsoleColor":
                    return String.Format("consolecolor:{0}", Item);
                default:
                    return "<type not supported>";
            }
        }
    }
}
