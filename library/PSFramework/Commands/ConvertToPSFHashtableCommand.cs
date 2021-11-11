using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Commands
{
    /// <summary>
    /// Implements the ConvertTo-PSFHashtable command
    /// </summary>
    [Cmdlet("ConvertTo", "PSFHashtable", DefaultParameterSetName = "filter")]
    [OutputType(new Type[] { typeof(Hashtable) })]
    public class ConvertToPSFHashtableCommand : PSCmdlet
    {
        #region Parameters
        /// <summary>
        /// The properties to include explicitly
        /// </summary>
        [Parameter(ParameterSetName = "filter")]
        public string[] Include = new string[0];

        /// <summary>
        /// Any properties to exclude explicitly
        /// </summary>
        [Parameter(ParameterSetName = "filter")]
        public string[] Exclude = new string[0];

        /// <summary>
        /// Enables case sensitivity.
        /// </summary>
        [Parameter()]
        public SwitchParameter CaseSensitive;

        /// <summary>
        /// Enables adding empty keys for explicitly included keys that were not found on the input
        /// </summary>
        [Parameter()]
        public SwitchParameter IncludeEmpty;

        /// <summary>
        /// Specifically designed for use in a command when passing through parameters with default values.
        /// Enabling this switch has the command inherit values from variables in the caller scope if their name has been specified in the Include parameter.
        /// </summary>
        [Parameter()]
        public SwitchParameter Inherit;

        /// <summary>
        /// Remap individual keys in the hashtable provided.
        /// Effectively renames entries in the hashtable.
        /// </summary>
        [Parameter()]
        public Hashtable Remap;

        /// <summary>
        /// The actual items to convert
        /// </summary>
        [Parameter(ValueFromPipeline = true)]
        public PSObject[] InputObject;

        /// <summary>
        /// Command to use as reference. Reads parameters from the command and use them as "Include" parameter.
        /// </summary>
        [Parameter(ParameterSetName = "reference")]
        public string ReferenceCommand;
        #endregion Parameters

        StringComparer _Comparison = StringComparer.InvariantCultureIgnoreCase;

        #region Cmdlet Methods
        /// <summary>
        /// Initialize command, resolving the ReferenceCommand if specified
        /// </summary>
        protected override void BeginProcessing()
        {
            if (String.IsNullOrEmpty(ReferenceCommand))
                return;

            CommandInfo info = InvokeCommand.GetCommand(ReferenceCommand, CommandTypes.Function | CommandTypes.Cmdlet | CommandTypes.Alias);
            if (info == null)
                throw new CommandNotFoundException($"Unable to find command: {ReferenceCommand}");
            Include = info.Parameters.Keys.ToArray();
        }

        /// <summary>
        /// Implements the basic processing logic to convert objects to hashtables
        /// </summary>
        protected override void ProcessRecord()
        {
            if (InputObject == null)
                return;

            if (CaseSensitive.ToBool())
                _Comparison = StringComparer.InvariantCulture;

            foreach (PSObject inputItem in InputObject)
            {
                if (inputItem == null)
                    continue;

                Hashtable result = new Hashtable(_Comparison);

                if (inputItem.BaseObject.GetType() == (typeof(Hashtable)))
                    result = (Hashtable)((Hashtable)inputItem.BaseObject).Clone();

                else if (inputItem.BaseObject as IDictionary != null)
                    result = new Hashtable(inputItem.BaseObject as IDictionary, _Comparison);

                else
                    foreach (string name in inputItem.Properties.Select(o => o.Name))
                        result[name] = inputItem.Properties[name].Value;

                if (Exclude.Length > 0)
                    foreach (string key in Exclude.Where(o => result.ContainsKey(o)))
                        result.Remove(key);

                if (Include.Length > 0)
                {
                    object[] keys = new object[result.Keys.Count];
                    result.Keys.CopyTo(keys, 0);
                    foreach (string key in keys.Where(o => !Include.Contains(o.ToString(), _Comparison) && result.ContainsKey(o)))
                        result.Remove(key);    
                    if (Inherit.ToBool())
                        foreach (string name in Include.Where(o => !result.ContainsKey(o)).Where(o => GetVariableValue(o) != null))
                            result[name] = GetVariableValue(name);
                    if (IncludeEmpty.ToBool())
                        foreach (string name in Include.Where(o => !result.ContainsKey(o)))
                            result[name] = null;
                }
                if (Remap != null)
                {
                    foreach (string key in Remap.Keys)
                    {
                        if (result.ContainsKey(key))
                        {
                            result[Remap[key]] = result[key];
                            result.Remove(key);
                        }
                    }
                }

                WriteObject(result);
            }
        }
        #endregion Cmdlet Methods
    }
}