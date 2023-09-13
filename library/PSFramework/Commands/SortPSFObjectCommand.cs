using System;
using System.Collections;
using System.Globalization;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Internal;
using System.Text;
using System.Threading.Tasks;
using PSFramework.Parameter;
using PSFramework.Validation;

namespace PSFramework.Commands
{
    /// <summary>
    /// Custom implementation of Sort-Object with PS7+ capabilities and custom property parsing
    /// </summary>
    [Cmdlet("Set",
            "PSFObjectOrder",
            HelpUri = "https://go.microsoft.com/fwlink/?LinkID=2097038",
            DefaultParameterSetName = "Default",
            RemotingCapability = RemotingCapability.None)]
    [Alias("Sort-PSFObject")]
    public class SortPSFObjectCommand : PSCmdlet
    {
        #region Parameters

        // Cmdlet

        /// <summary>
        /// Gets or sets a value indicating whether a stable sort is required.
        /// </summary>
        /// <value></value>
        /// <remarks>
        /// Items that are duplicates according to the sort algorithm will appear
        /// in the same relative order in a stable sort.
        /// </remarks>
        [Parameter(ParameterSetName = "Default")]
        [PsfValidatePSVersion("7.0", "PSFramework.Sort-PSFObject.IgnoreVersionError")]
        public SwitchParameter Stable { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the sort order is descending.
        /// </summary>
        [Parameter]
        public SwitchParameter Descending { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the sort filters out any duplicate objects.
        /// </summary>
        /// <value></value>
        [Parameter]
        public SwitchParameter Unique { get; set; }

        /// <summary>
        /// Gets or sets the number of items to return in a Top N sort.
        /// </summary>
        [Parameter(ParameterSetName = "Top", Mandatory = true)]
        [PsfValidatePSVersion("7.0", "PSFramework.Sort-PSFObject.IgnoreVersionError")]
        [ValidateRange(1, int.MaxValue)]
        public int Top { get; set; }

        /// <summary>
        /// Gets or sets the number of items to return in a Bottom N sort.
        /// </summary>
        [Parameter(ParameterSetName = "Bottom", Mandatory = true)]
        [PsfValidatePSVersion("7.0", "PSFramework.Sort-PSFObject.IgnoreVersionError")]
        [ValidateRange(1, int.MaxValue)]
        public int Bottom { get; set; }

        // ObjectBase

        /// <summary>
        /// </summary>
        [Parameter(ValueFromPipeline = true)]
        public PSObject InputObject { get; set; } = AutomationNull.Value;

        /// <summary>
        /// Gets or Sets the Properties that would be used for Grouping, Sorting and Comparison.
        /// </summary>
        [Parameter(Position = 0)]
        [PSFCore.NoJeaParameter()]
        [Validation.PsfValidateTrustedData()]
        public SortParameter[] Property { get; set; }

        // ObjectCmdletBase

        /// <summary>
        /// </summary>
        /// <value></value>
        [Parameter]
        public string Culture { get; set; }

        /// <summary>
		/// Indicates that the sort is case-sensitive. By default, sorts aren't case-sensitive.
        /// </summary>
        /// <value></value>
        [Parameter]
        public SwitchParameter CaseSensitive { get; set; }
        #endregion Parameters

        #region Private Fields
        /// <summary>
        /// List of properties to NOT clone into the hashtable used against Select-Object
        /// </summary>
        private string[] _NonclonedProperties = new string[] { "Property" };

        /// <summary>
        /// List of properties that require at least PowerShell V7
        /// </summary>
        private string[] _PS7Properties = new string[] { "Stable", "Top", "Bottom" };

        /// <summary>
        /// The pipeline that is wrapped around Select-Object
        /// </summary>
        private SteppablePipeline _Pipeline;

        /// <summary>
        /// Name of the temporary variable created in the caller scope
        /// </summary>
        private string _VarName;
        #endregion Private Fields

        #region Cmdlet Implementation
        /// <summary>
        /// Execute begin step
        /// </summary>
        protected override void BeginProcessing()
        {
            object outBuffer;
            if (MyInvocation.BoundParameters.TryGetValue("OutBuffer", out outBuffer))
            {
                MyInvocation.BoundParameters["OutBuffer"] = 1;
            }

            Hashtable clonedBoundParameters = new Hashtable();
            foreach (string key in MyInvocation.BoundParameters.Keys)
                if (!_NonclonedProperties.Contains(key))
                    if (PSFCore.PSFCoreHost.PSVersion.Major >= 7 || !_PS7Properties.Contains(key))
                        clonedBoundParameters[key] = MyInvocation.BoundParameters[key];

            if (MyInvocation.BoundParameters.ContainsKey("Property"))
                clonedBoundParameters["Property"] = Property.Select(o => o.Value).AsEnumerable().ToArray();
            // Set the list of parameters to a variable in the caller scope, so it can be splatted
            _VarName = $"__PSFramework_SortParam_{(new Random()).Next(10000,100000)}";
            SessionState.PSVariable.Set(_VarName, clonedBoundParameters);
            ScriptBlock scriptCommand = ScriptBlock.Create($"Sort-Object @{_VarName}");
            _Pipeline = scriptCommand.GetSteppablePipeline(MyInvocation.CommandOrigin);

            _Pipeline.Begin(this);
        }

        /// <summary>
        /// Execute process step
        /// </summary>
        protected override void ProcessRecord()
        {
            _Pipeline.Process(InputObject);
        }

        /// <summary>
        /// Execute end step
        /// </summary>
        protected override void EndProcessing()
        {
            _Pipeline.End();
            SessionState.PSVariable.Remove(_VarName);
        }
        #endregion Cmdlet Implementation
    }
}
