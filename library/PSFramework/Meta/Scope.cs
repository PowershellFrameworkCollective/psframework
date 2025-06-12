using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Meta
{
    public class Scope
    {
        internal object _Scope;
        public string Type { get; internal set; }

        #region Factory
        public static Scope Global()
        {
            Scope temp = new Scope();
            object sessionState = UtilityHost.GetPrivateProperty("SessionState", UtilityHost.GetExecutionContextFromTLS());
            object sessionStateInternal = UtilityHost.GetPrivateProperty("Internal", sessionState);
            temp._Scope = UtilityHost.GetPrivateProperty("GlobalScope", sessionStateInternal);
            temp.Type = "Global";
            return temp;
        }

        public static Scope Module()
        {
            Scope temp = new Scope();
            object sessionState = UtilityHost.GetPrivateProperty("SessionState", UtilityHost.GetExecutionContextFromTLS());
            object sessionStateInternal = UtilityHost.GetPrivateProperty("Internal", sessionState);
            temp._Scope = UtilityHost.GetPrivateProperty("ModuleScope", sessionStateInternal);
            temp.Type = "Module";
            return temp;
        }

        public static Scope Script()
        {
            Scope temp = new Scope();
            object sessionState = UtilityHost.GetPrivateProperty("SessionState", UtilityHost.GetExecutionContextFromTLS());
            object sessionStateInternal = UtilityHost.GetPrivateProperty("Internal", sessionState);
            temp._Scope = UtilityHost.GetPrivateProperty("ScriptScope", sessionStateInternal);
            temp.Type = "Script";
            return temp;
        }

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
        public void EnableVariables() { _VariablesEnabled = true; }
        public void DisableVariables() { _VariablesEnabled = false; }

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

        public bool HasVariable(string Name)
            { return null != _Scope && _Variables.ContainsKey(Name); }
        public object GetVariableValue(string Name)
        {
            if (null == _Scope)
                return null;
            if (!HasVariable(Name))
                return null;
            return _Variables[Name].Value;
        }
        public void SetVariable(string Name, object Value)
        {
            if (null == _Scope)
                return;
            _Variables[Name] = new PSVariable(Name, Value);
        }
        #endregion Variables

        #region Aliases
        private bool _AliasesEnabled;
        public void EnableAliases() { _AliasesEnabled = true; }
        public void DisableAliases() { _AliasesEnabled = false; }

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
        public void EnableFunctions() { _FunctionsEnabled = true; }
        public void DisableFunctions() { _FunctionsEnabled = false; }

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
        public void EnableCmdlets() { _CmdletsEnabled = true; }
        public void DisableCmdlets() { _CmdletsEnabled = false; }

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
        public void EnableDrives() { _DrivesEnabled = true; }
        public void DisableDrives() { _DrivesEnabled = false; }

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
    }
}
