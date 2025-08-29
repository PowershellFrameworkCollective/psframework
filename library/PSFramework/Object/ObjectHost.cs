using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Object
{
    /// <summary>
    /// Provides centralized utilities for interacting with PowerShell objects.
    /// </summary>
    public static class ObjectHost
    {
        #region Member Manipulation
        /// <summary>
        /// Add a set of noteproperties to the specified PowerShell object
        /// </summary>
        /// <param name="Item">The object to extend</param>
        /// <param name="Members">The set of properties to add</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddNoteProperty(PSObject Item, Hashtable Members, bool PreValidated = true)
        {
            foreach (object key in Members.Keys)
            {
                PSNoteProperty property = new PSNoteProperty((string)key, Members[key]);
                Item.Properties.Add(property, PreValidated);
            }
        }

        /// <summary>
        /// Add a set of noteproperties to all specified PowerShell objects
        /// </summary>
        /// <param name="Items">The objects to extend</param>
        /// <param name="Members">The set of properties to add</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddNotePropertyBulk(PSObject[] Items, Hashtable Members, bool PreValidated = true)
        {
            foreach (object key in Members.Keys)
            {
                PSNoteProperty property = new PSNoteProperty((string)key, Members[key]);
                foreach (PSObject item in Items)
                    item.Properties.Add(property, PreValidated);
            }
        }

        /// <summary>
        /// Adds a single noteproperty to the specified PowerShell object
        /// </summary>
        /// <param name="Item">The object to extend</param>
        /// <param name="Name">The name of the property to add</param>
        /// <param name="Value">The value to assign to the new property</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddNoteProperty(PSObject Item, string Name, object Value, bool PreValidated = true)
        {
            PSNoteProperty property = new PSNoteProperty(Name, Value);
            Item.Properties.Add(property, PreValidated);
        }

        /// <summary>
        /// Adds a single noteproperty to a lot of specified PowerShell objects
        /// </summary>
        /// <param name="Items">The objects to extend</param>
        /// <param name="Name">The name of the property to add</param>
        /// <param name="Value">The value to assign to the new property</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddNotePropertyBulk(PSObject[] Items, string Name, object Value, bool PreValidated = true)
        {
            PSNoteProperty property = new PSNoteProperty(Name, Value);
            foreach (PSObject item in Items)
                item.Properties.Add(property, PreValidated);
        }

        /// <summary>
        /// Adds a script-calculated property to the specified PowerShell object
        /// </summary>
        /// <param name="Item">The object to extend</param>
        /// <param name="Name">The name of the script-property to add</param>
        /// <param name="Get">The code used to read the value</param>
        /// <param name="Set">(optional) The code used when assigning input to the property.</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddScriptProperty(PSObject Item, string Name, ScriptBlock Get, ScriptBlock Set = null, bool PreValidated = true)
        {
            PSScriptProperty property = new PSScriptProperty(Name, Get, Set);
            Item.Properties.Add(property, PreValidated);
        }

        /// <summary>
        /// Adds a script-calculated property to the specified PowerShell objects
        /// </summary>
        /// <param name="Items">The objects to extend</param>
        /// <param name="Name">The name of the script-property to add</param>
        /// <param name="Get">The code used to read the value</param>
        /// <param name="Set">(optional) The code used when assigning input to the property.</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddScriptPropertyBulk(PSObject[] Items, string Name, ScriptBlock Get, ScriptBlock Set = null, bool PreValidated = true)
        {
            PSScriptProperty property = new PSScriptProperty(Name, Get, Set);
            foreach (PSObject item in Items)
                item.Properties.Add(property, PreValidated);
        }

        /// <summary>
        /// Removes a member from the specified PowerShell object
        /// </summary>
        /// <param name="Item">The object to remove a member from</param>
        /// <param name="Name">The name of the member to remove.</param>
        public static void RemoveMember(PSObject Item, string Name)
        {
            Item.Members.Remove(Name);
        }

        /// <summary>
        /// Removes a member from the specified PowerShell objects
        /// </summary>
        /// <param name="Items">The objects to remove a member from</param>
        /// <param name="Name">The name of the member to remove.</param>
        public static void RemoveMemberBulk(PSObject[] Items, string Name)
        {
            foreach (PSObject item in Items)
                item.Members.Remove(Name);
        }

        /// <summary>
        /// Adds a script-based method to the specified PowerShell object
        /// </summary>
        /// <param name="Item">The object to extend</param>
        /// <param name="Name">The name of the method to add.</param>
        /// <param name="Code">The code implementing the logic when the method is called.</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddScriptMethod(PSObject Item, string Name, ScriptBlock Code, bool PreValidated = true)
        {
            PSScriptMethod method = new PSScriptMethod(Name, Code);
            Item.Methods.Add(method, PreValidated);
        }

        /// <summary>
        /// Adds a script-based method to the specified PowerShell objects
        /// </summary>
        /// <param name="Items">The objects to extend</param>
        /// <param name="Name">The name of the method to add.</param>
        /// <param name="Code">The code implementing the logic when the method is called.</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddScriptMethodBulk(PSObject[] Items, string Name, ScriptBlock Code, bool PreValidated = true)
        {
            PSScriptMethod method = new PSScriptMethod(Name, Code);
            foreach (PSObject item in Items)
                item.Methods.Add(method, PreValidated);
        }

        /// <summary>
        /// Adds several script methods to the specified PowerShell object
        /// </summary>
        /// <param name="Item">The object to extend</param>
        /// <param name="Members">The methods to add. Provide a hashtable mapping method name to scriptblock with the logic implementing the method.</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddScriptMethod(PSObject Item, Hashtable Members, bool PreValidated = true)
        {
            foreach (object key in Members.Keys)
            {
                PSScriptMethod method = new PSScriptMethod((string)key, (ScriptBlock)Members[key]);
                Item.Methods.Add(method, PreValidated);
            }
        }

        /// <summary>
        /// Adds several script methods to the specified PowerShell objects
        /// </summary>
        /// <param name="Items">The objects to extend</param>
        /// <param name="Members">The methods to add. Provide a hashtable mapping method name to scriptblock with the logic implementing the method.</param>
        /// <param name="PreValidated">Whether validation has already been performed and need not be done. Setting this to false will add performance overhead.</param>
        public static void AddScriptMethodBulk(PSObject[] Items, Hashtable Members, bool PreValidated = true)
        {
            foreach (object key in Members.Keys)
            {
                PSScriptMethod method = new PSScriptMethod((string)key, (ScriptBlock)Members[key]);
                foreach (PSObject item in Items)
                    item.Methods.Add(method, PreValidated);
            }
        }
        #endregion Member Manipulation
    }
}