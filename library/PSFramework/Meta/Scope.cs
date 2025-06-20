using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Meta
{
    /// <summary>
    /// Wrapper exposing a PowerShell scope and all its content.
    /// </summary>
    public class Scope
    {
        internal object _Scope;

        /// <summary>
        /// What kind of scope it is.
        /// </summary>
        public string Type { get; internal set; }

        #region Constructors
        /// <summary>
        /// Creates an empty scope object
        /// </summary>
        internal Scope() { }

        /// <summary>
        /// Creates a scope object, wrapping around a previously reflected PS scope object.
        /// </summary>
        /// <param name="RawScope">The raw scope object, as obtained from the PowerShell engine via reflection.</param>
        internal Scope(object RawScope)
        {
            _Scope = RawScope;
            VerifyType();
        }
        #endregion Constructors

        #region Factory
        /// <summary>
        /// Get a representation of the global scope.
        /// </summary>
        /// <returns>a representation of the global scope</returns>
        public static Scope Global()
        {
            Scope temp = new Scope();
            object sessionState = UtilityHost.GetPrivateProperty("SessionState", UtilityHost.GetExecutionContextFromTLS());
            object sessionStateInternal = UtilityHost.GetPrivateProperty("Internal", sessionState);
            temp._Scope = UtilityHost.GetPrivateProperty("GlobalScope", sessionStateInternal);
            temp.Type = "Global";
            return temp;
        }

        /// <summary>
        /// Get a representation of the module scope.
        /// </summary>
        /// <returns>a representation of the module scope</returns>
        public static Scope Module()
        {
            Scope temp = new Scope();
            object sessionState = UtilityHost.GetPrivateProperty("SessionState", UtilityHost.GetExecutionContextFromTLS());
            object sessionStateInternal = UtilityHost.GetPrivateProperty("Internal", sessionState);
            temp._Scope = UtilityHost.GetPrivateProperty("ModuleScope", sessionStateInternal);
            temp.Type = "Module";
            return temp;
        }

        /// <summary>
        /// Get a representation of the script scope.
        /// </summary>
        /// <returns>a representation of the script scope</returns>
        public static Scope Script()
        {
            Scope temp = new Scope();
            object sessionState = UtilityHost.GetPrivateProperty("SessionState", UtilityHost.GetExecutionContextFromTLS());
            object sessionStateInternal = UtilityHost.GetPrivateProperty("Internal", sessionState);
            temp._Scope = UtilityHost.GetPrivateProperty("ScriptScope", sessionStateInternal);
            temp.Type = "Script";
            return temp;
        }

        /// <summary>
        /// Get a representation of the current scope.
        /// </summary>
        /// <returns>a representation of the current scope</returns>
        public static Scope Current()
        {
            Scope temp = new Scope();
            object sessionState = UtilityHost.GetPrivateProperty("SessionState", UtilityHost.GetExecutionContextFromTLS());
            object sessionStateInternal = UtilityHost.GetPrivateProperty("Internal", sessionState);
            temp._Scope = UtilityHost.GetPrivateProperty("CurrentScope", sessionStateInternal);
            temp.Type = "Current";
            return temp;
        }
        #endregion Factory

        #region Reflection
        #region Variables
        private bool _VariablesEnabled;
        /// <summary>
        /// Enable access to variable content of the scope.
        /// </summary>
        public void EnableVariables() { _VariablesEnabled = true; }

        /// <summary>
        /// Disable access to variable content of the scope.
        /// </summary>
        public void DisableVariables() { _VariablesEnabled = false; }

        /// <summary>
        /// The variables contained in the scope
        /// </summary>
        public Dictionary<string, PSVariable> Variables
        {
            get
            {
                if (null == _Scope || !_VariablesEnabled)
                    return null;
                return (Dictionary<string, PSVariable>)UtilityHost.GetPrivateField("_variables", _Scope);
            }
        }

        private Dictionary<string, PSVariable> _Variables
        {
            get
            {
                if (null == _Scope)
                    return null;
                return (Dictionary<string, PSVariable>)UtilityHost.GetPrivateField("_variables", _Scope);
            }
        }

        /// <summary>
        /// Checks whether a specific variable exists in the scope
        /// </summary>
        /// <param name="Name">Name of the variable to scan for</param>
        /// <returns>Whether the variable exists</returns>
        public bool HasVariable(string Name)
            { return null != _Scope && _Variables.ContainsKey(Name); }

        /// <summary>
        /// Retrieve the value of a variable in the scope.
        /// Returns null if scope or variable do not exist.
        /// </summary>
        /// <param name="Name">Name of the variable to retrieve.</param>
        /// <returns>The value of the variable.</returns>
        public object GetVariableValue(string Name)
        {
            if (null == _Scope)
                return null;
            if (!HasVariable(Name))
                return null;
            return _Variables[Name].Value;
        }

        /// <summary>
        /// Change the value of a variable, in effect overwriting it.
        /// </summary>
        /// <param name="Name">The name of the variable to apply</param>
        /// <param name="Value">The value to assign to the variable</param>
        public void SetVariable(string Name, object Value)
        {
            if (null == _Scope)
                return;
            _Variables[Name] = new PSVariable(Name, Value);
        }
        #endregion Variables

        #region Aliases
        private bool _AliasesEnabled;
        /// <summary>
        /// Enable access to alias content of the scope.
        /// </summary>
        public void EnableAliases() { _AliasesEnabled = true; }

        /// <summary>
        /// Disable access to alias content of the scope.
        /// </summary>
        public void DisableAliases() { _AliasesEnabled = false; }

        /// <summary>
        /// The aliases of the scope
        /// </summary>
        public Dictionary<string, AliasInfo> Aliases
        {
            get
            {
                if (null == _Scope || !_AliasesEnabled)
                    return null;
                return (Dictionary<string, AliasInfo>)UtilityHost.GetPrivateField("_alias", _Scope);
            }
        }
        #endregion Aliases

        #region Functions
        private bool _FunctionsEnabled;
        /// <summary>
        /// Enable access to function content of the scope.
        /// </summary>
        public void EnableFunctions() { _FunctionsEnabled = true; }

        /// <summary>
        /// Disable access to function content of the scope.
        /// </summary>
        public void DisableFunctions() { _FunctionsEnabled = false; }

        /// <summary>
        /// The functions defined within the scope.
        /// </summary>
        public Dictionary<string, FunctionInfo> Functions
        {
            get
            {
                if (null == _Scope || !_FunctionsEnabled)
                    return null;
                return (Dictionary<string, FunctionInfo>)UtilityHost.GetPrivateField("_functions", _Scope);
            }
        }
        #endregion Functions

        #region Cmdlets
        private bool _CmdletsEnabled;
        /// <summary>
        /// Enable access to cmdlet content of the scope.
        /// </summary>
        public void EnableCmdlets() { _CmdletsEnabled = true; }

        /// <summary>
        /// Disable access to cmdlet content of the scope.
        /// </summary>
        public void DisableCmdlets() { _CmdletsEnabled = false; }

        /// <summary>
        /// The Cmdlets contained within the scope
        /// </summary>
        public Dictionary<string, CmdletInfo> Cmdlets
        {
            get
            {
                if (null == _Scope || !_CmdletsEnabled)
                    return null;
                return (Dictionary<string, CmdletInfo>)UtilityHost.GetPrivateField("_cmdlets", _Scope);
            }
        }
        #endregion Cmdlets

        #region Drives
        private bool _DrivesEnabled;
        /// <summary>
        /// Enable access to PSDrivecontent of the scope.
        /// </summary>
        public void EnableDrives() { _DrivesEnabled = true; }

        /// <summary>
        /// Disable access to PSDrivecontent of the scope.
        /// </summary>
        public void DisableDrives() { _DrivesEnabled = false; }

        /// <summary>
        /// The PSDrives contained within the scope
        /// </summary>
        public Dictionary<string, PSDriveInfo> Drives
        {
            get
            {
                if (null == _Scope || !_DrivesEnabled)
                    return null;
                return (Dictionary<string, PSDriveInfo>)UtilityHost.GetPrivateField("_drives", _Scope);
            }
        }
        #endregion Drives
        #endregion Reflection
    
        /// <summary>
        /// The Parent Scope of the current scope
        /// </summary>
        public Scope Parent
        {
            get
            {
                object parentScope = UtilityHost.GetPrivateProperty("Parent", _Scope);
                if (null == parentScope)
                    return null;

                return new Scope(parentScope);
            }
        }

        /// <summary>
        /// Update the assigned Type.
        /// Intended when generating a scope based on another scope.
        /// </summary>
        internal void VerifyType()
        {
            if (_Scope == Global()._Scope)
                Type = "Global";
            else if (Type == "Module")
                Type = "Module";
            else if (_Scope == UtilityHost.GetPrivateProperty("ScriptScope", _Scope))
                Type = "Script";
            else if (Type == "Current")
                Type = "Current";
            else
                Type = "Unknown";
        }
    }
}
