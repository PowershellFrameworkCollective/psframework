using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Linq;
using PSFramework.PSFCore;
using PSFramework.TabExpansion;

namespace PSFramework.Commands
{
    /// <summary>
    /// Implements the ConvertTo-PSFHashtable command
    /// </summary>
    [Cmdlet(VerbsData.ConvertTo, "PSFHashtable")]
    [OutputType(new Type[] { typeof(Hashtable) })]
    public class ConvertToPSFHashtableCommand : PSCmdlet
    {
        #region Parameters
        /// <summary>
        /// The properties to include explicitly
        /// </summary>
        [Parameter()] 
        public string[] Include = new string[0];

        /// <summary>
        /// Any properties to exclude explicitly
        /// </summary>
        [Parameter()] 
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
        /// Inherit from all parameters of the calling command, including all non-bound parameters.
        /// </summary>
        public SwitchParameter InheritParameters;

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
        [Parameter()]
        public string ReferenceCommand;

        /// <summary>
        /// The parameterset of the command to reference. Reads parameters from the specified parameterset of the command and use them as "Include" parameter.
        /// </summary>
        [Parameter()]
        [PsfArgumentCompleter("PSFramework.Utility.ParameterSetNames")]
        public string ReferenceParameterSetName;

        /// <summary>
        /// Return the resulting hashtable as a PsfHashtable, which can later have a default value.
        /// </summary>
        [Parameter()]
        public SwitchParameter AsPsfHashtable;
        #endregion Parameters

        StringComparer _Comparison = StringComparer.InvariantCultureIgnoreCase;
        List<string> _ToInclude = new List<string>();

        #region Cmdlet Methods
        /// <summary>
        /// Initialize command, resolving the ReferenceCommand if specified
        /// </summary>
        protected override void BeginProcessing()
        {
            if (Include != null)
                _ToInclude.AddRange(Include);

            if (CaseSensitive.ToBool())
                _Comparison = StringComparer.InvariantCulture;

            if (Remap != null && (MyInvocation.BoundParameters.ContainsKey("Include") || !String.IsNullOrEmpty(ReferenceCommand)))
            {
                foreach (object key in Remap.Keys)
                    _ToInclude.Add(key.ToString());
            }

            if (String.IsNullOrEmpty(ReferenceCommand))
                return;

            CommandInfo info = null;
            using (PowerShell ps = PowerShell.Create(RunspaceMode.CurrentRunspace))
            {
                ps.AddCommand(InvokeCommand.GetCmdlet("Get-Command"))
                    .AddParameter("Name", ReferenceCommand)
                    .AddParameter("ErrorAction", ActionPreference.SilentlyContinue);
                info = ps.Invoke()[0]?.BaseObject as CommandInfo;
            }

            PSFCoreHost.WriteDebug("ConvertTo-PSFHashTable: ReferenceCommand", info);

            if (info == null)
                throw new CommandNotFoundException($"Unable to find command: {ReferenceCommand}");
            if (String.IsNullOrEmpty(ReferenceParameterSetName))
                _ToInclude.AddRange(info.Parameters.Keys.ToArray());
            else
            {
                var parameterSets = info.ParameterSets.Where(o => String.Equals(o.Name, ReferenceParameterSetName, StringComparison.InvariantCultureIgnoreCase));
                if (parameterSets.Count() != 1)
                    throw new ArgumentException($"Parameterset {ReferenceParameterSetName} not found on command {info.Name}!");
                PSFCoreHost.WriteDebug("ConvertTo-PSFHashTable: ReferenceCommand / ParameterSet", parameterSets);
                _ToInclude.AddRange(parameterSets.First().Parameters.Select(o => o.Name).ToArray());
            }
        }

        /// <summary>
        /// Implements the basic processing logic to convert objects to hashtables
        /// </summary>
        protected override void ProcessRecord()
        {
            if (InputObject == null)
                return;

            foreach (PSObject inputItem in InputObject)
            {
                if (inputItem == null)
                    continue;

                Hashtable result = new Hashtable(_Comparison);

                if (inputItem.BaseObject.GetType() == typeof(Hashtable) && !MyInvocation.BoundParameters.ContainsKey("CaseSensitive"))
                    result = (Hashtable)((Hashtable)inputItem.BaseObject).Clone();

                else if (inputItem.BaseObject as IDictionary != null)
                    try { result = new Hashtable(inputItem.BaseObject as IDictionary, _Comparison); }
                    catch (Exception e)
                    {
                        WriteError(new ErrorRecord(e, "ConversionError", ErrorCategory.InvalidArgument, inputItem));
                        continue;
                    }

                else
                    foreach (string name in inputItem.Properties.Select(o => o.Name))
                        result[name] = inputItem.Properties[name].Value;

                if (Exclude.Length > 0)
                    foreach (string key in Exclude.Where(o => result.ContainsKey(o)))
                        result.Remove(key);

                if (_ToInclude.Count > 0)
                {
                    object[] keys = new object[result.Keys.Count];
                    result.Keys.CopyTo(keys, 0);
                    foreach (string key in keys.Where(o => !_ToInclude.Contains(o.ToString(), _Comparison) && result.ContainsKey(o)))
                        result.Remove(key);    
                    if (Inherit.ToBool())
                        foreach (string name in _ToInclude.Where(o => !result.ContainsKey(o)).Where(o => GetVariableValue(o) != null))
                            result[name] = GetVariableValue(name);
                    if (IncludeEmpty.ToBool())
                        foreach (string name in _ToInclude.Where(o => !result.ContainsKey(o)))
                            result[name] = null;
                }
                if (Remap != null)
                {
                    foreach (string key in Remap.Keys)
                    {
                        if (result.ContainsKey(key))
                        {
                            object value = result[key];
                            result.Remove(key);
                            result[Remap[key]] = value;
                        }
                    }
                }

                if (AsPsfHashtable.ToBool())
                    result = new Object.PsfHashtable(result);

                WriteObject(result);
            }
        }
        #endregion Cmdlet Methods
    }
}