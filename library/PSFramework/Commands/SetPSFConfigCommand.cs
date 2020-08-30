using PSFramework.Configuration;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;

namespace PSFramework.Commands
{
    /// <summary>
    /// Implements the Set-PSFConfig command
    /// </summary>
    [Cmdlet("Set", "PSFConfig", DefaultParameterSetName = "FullName")]
    public class SetPSFConfigCommand : PSFCmdlet
    {
        #region Parameters
        /// <summary>
        /// The full name of the setting
        /// </summary>
        [Parameter(ParameterSetName = "FullName", Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, ValueFromPipeline = true)]
        [Parameter(ParameterSetName = "Persisted", Position = 0, Mandatory = true, ValueFromPipelineByPropertyName = true, ValueFromPipeline = true)]
        public string FullName;

        /// <summary>
        /// The name of the module the setting belongs to.
        /// Is optional due to just specifying a name is legal, in which case the first name segment becomes the module name.
        /// </summary>
        [Parameter(ParameterSetName = "Module", Position = 0, ValueFromPipelineByPropertyName = true)]
        public string Module;

        /// <summary>
        /// The name of the setting within a module.
        /// </summary>
        [Parameter(ParameterSetName = "Module", Position = 1, Mandatory = true, ValueFromPipelineByPropertyName = true)]
        public string Name;

        /// <summary>
        /// The value to apply.
        /// </summary>
        [Parameter(ParameterSetName = "FullName", Position = 1)]
        [Parameter(ParameterSetName = "Module", Position = 2)]
        [AllowNull]
        [AllowEmptyCollection]
        [AllowEmptyString]
        public object Value;

        /// <summary>
        /// The persisted value to apply.
        /// </summary>
        [Parameter(ParameterSetName = "Persisted", Mandatory = true)]
        public string PersistedValue;

        /// <summary>
        /// The persisted type to apply.
        /// </summary>
        [Parameter(ParameterSetName = "Persisted")]
        public ConfigurationValueType PersistedType;

        /// <summary>
        /// Add documentation to the setting.
        /// </summary>
        [Parameter()]
        public string Description;

        /// <summary>
        /// The validation script to use.
        /// </summary>
        [Parameter()]
        public string Validation;

        /// <summary>
        /// The handling script to apply when changing the value.
        /// </summary>
        [Parameter()]
        public ScriptBlock Handler;

        /// <summary>
        /// Whether the setting should be hidden from casual discovery.
        /// </summary>
        [Parameter()]
        public SwitchParameter Hidden;

        /// <summary>
        /// Whether the setting should be applied only when nothing exists yet.
        /// </summary>
        [Parameter()]
        public SwitchParameter Default;

        /// <summary>
        /// Whether this is the configuration initialization call.
        /// </summary>
        [Parameter()]
        public SwitchParameter Initialize;

        /// <summary>
        /// Enabling this will cause the module to use friendly json notation on export to file.
        /// This may result in loss of data precision, but is more userfriendly.
        /// </summary>
        [Parameter()]
        public SwitchParameter SimpleExport;

        /// <summary>
        /// Whether this setting applies to module scope file export.
        /// </summary>
        [Parameter()]
        public SwitchParameter ModuleExport;

        /// <summary>
        /// Allow the setting to be deleted from memory. Has no effect after initialization.
        /// </summary>
        [Parameter()]
        public SwitchParameter AllowDelete;

        /// <summary>
        /// Do not apply the validation script when changing values.
        /// </summary>
        [Parameter()]
        public SwitchParameter DisableValidation;

        /// <summary>
        /// Do not run the handler script when changing values.
        /// </summary>
        [Parameter()]
        public SwitchParameter DisableHandler;

        /// <summary>
        /// Return the changed configuration setting.
        /// </summary>
        [Parameter()]
        public SwitchParameter PassThru;

        /// <summary>
        /// Enable throwing exceptions.
        /// </summary>
        [Parameter()]
        public SwitchParameter EnableException;
        #endregion Parameters

        #region Private fields
        /// <summary>
        /// The configuration item changed
        /// </summary>
        private Config _Config;

        /// <summary>
        /// Whether this is an initialization execution.
        /// </summary>
        private bool _Initialize;

        /// <summary>
        /// Whether persisted values need to be restored.
        /// </summary>
        private bool _Persisted;

        /// <summary>
        /// Whether the setting already exists.
        /// </summary>
        private bool _Exists;

        /// <summary>
        /// The setting to be affected was enforced by policy and cannot be changed by the user.
        /// </summary>
        private bool _PolicyEnforced;

        /// <summary>
        /// Processed name of module.
        /// </summary>
        private string _NameModule;

        /// <summary>
        /// Processed name of setting within module.
        /// </summary>
        private string _NameName;

        /// <summary>
        /// Processed full name of setting.
        /// </summary>
        private string _NameFull;

        /// <summary>
        /// The reason validation failed.
        /// Filled by ApplyValue.
        /// </summary>
        private string _ValidationErrorMessage;
        #endregion Private fields

        #region Cmdlet methods
        /// <summary>
        /// Implements the process action of Set-PSFConfig
        /// </summary>
        protected override void ProcessRecord()
        {
            if (!String.IsNullOrEmpty(Validation) && !ConfigurationHost.Validation.ContainsKey(Validation))
            {
                StopCommand(String.Format("Invalid validation name: {0}. Supported validations: {1}",Validation, String.Join(", ", ConfigurationHost.Validation.Keys)), null, Validation, "Set-PSFConfig", "PSFramework", "SetPSFConfigCommand.cs", 0, null, EnableException.ToBool());
                return;
            }

            #region Name Interpretation
            if (!String.IsNullOrEmpty(FullName))
            {
                _NameFull = FullName.Trim('.');
                if (!_NameFull.Contains('.'))
                {
                    StopCommand($"Invalid Name: {FullName} ! At least one '.' is required, to separate module from name", null, FullName, "Set-PSFConfig", "PSFramework", "SetPSFConfigCommand.cs", 0, null, EnableException.ToBool());
                    return;
                }

                int index = _NameFull.IndexOf('.');
                _NameModule = _NameFull.Substring(0, index);
                _NameName = _NameFull.Substring(index + 1);
            }
            else
            {
                if (!String.IsNullOrEmpty(Module))
                {
                    _NameModule = Module.Trim('.', ' ');
                    _NameName = Name.Trim('.', ' ');
                    _NameFull = String.Format("{0}.{1}", _NameModule, _NameName);
                }
                else
                {
                    _NameFull = Name.Trim('.');
                    if (!_NameFull.Contains('.'))
                    {
                        StopCommand($"Invalid Name: {Name} ! At least one '.' is required, to separate module from name", null, Name, "Set-PSFConfig", "PSFramework", "SetPSFConfigCommand.cs", 0, null, EnableException.ToBool());
                        return;
                    }

                    int index = _NameFull.IndexOf('.');
                    _NameModule = _NameFull.Substring(0, index);
                    _NameName = _NameFull.Substring(index + 1);
                }
            }

            if (String.IsNullOrEmpty(_NameModule) || String.IsNullOrEmpty(_NameName))
            {
                StopCommand($"Invalid Name: {_NameFull} ! Need to specify a legally namespaced name!", null, _NameFull, "Set-PSFConfig", "PSFramework", "SetPSFConfigCommand.cs", 0, null, EnableException.ToBool());
                return;
            }
            #endregion Name Interpretation

            _Exists = ConfigurationHost.Configurations.ContainsKey(_NameFull);
            if (_Exists)
                _Config = ConfigurationHost.Configurations[_NameFull];
            _Initialize = Initialize;
            _Persisted = !String.IsNullOrEmpty(PersistedValue);
            _PolicyEnforced = (_Exists && _Config.PolicyEnforced);

            // If the setting is already initialized, nothing should be done
            if (_Exists && _Config.Initialized && Initialize)
                return;

            if (_Initialize)
                ExecuteInitialize();
            else if (!_Exists && _Persisted)
                ExecuteNewPersisted();
            else if (_Exists && _Persisted)
                ExecuteUpdatePersisted();
            else if (_Exists)
                ExecuteUpdate();
            else
                ExecuteNew();

            if (PassThru.ToBool() && (_Config != null))
                WriteObject(_Config);
        }
        #endregion Cmdlet methods

        #region Private Methods
        private void ExecuteInitialize()
        {
            object oldValue = null;
            if (_Exists)
                oldValue = _Config.Value;
            else
                _Config = new Config();

            _Config.Name = _NameName;
            _Config.Module = _NameModule;
            _Config.Value = Value;
            
            ApplyCommonSettings();

            // Do it again even though it is part of common settings
            // The common settings are only applied if the parameter is set, this always will.
            _Config.AllowDelete = AllowDelete.ToBool();

            _Config.Initialized = true;
            ConfigurationHost.Configurations[_NameFull] = _Config;

            if (_Exists)
            {
                try { ApplyValue(oldValue); }
                catch (Exception e)
                {
                    StopCommand($"Could not update configuration: {_NameFull}", e, _NameFull, "Set-PSFConfig", "PSFramework", "SetPSFConfigCommand.cs", 0, null, EnableException.ToBool());
                    return;
                }
            }
        }

        private void ExecuteNew()
        {
            _Config = new Config();
            _Config.Name = _NameName;
            _Config.Module = _NameModule;
            _Config.Value = Value;
            
            ApplyCommonSettings();
            ConfigurationHost.Configurations[_NameFull] = _Config;
        }

        private void ExecuteUpdate()
        {
            if (_PolicyEnforced)
            {
                StopCommand($"Could not update configuration: {_NameFull} - The current settings have been enforced by policy!", null, _NameFull, "Set-PSFConfig", "PSFramework", "SetPSFConfigCommand.cs", 0, null, EnableException.ToBool());
                return;
            }
            ApplyCommonSettings();

            if (!MyInvocation.BoundParameters.ContainsKey("Value"))
                return;

            try {
                if (!Default)
                    ApplyValue(Value);
            }
            catch (Exception e)
            {
                StopCommand($"Could not update configuration: {_NameFull}", e, _NameFull, "Set-PSFConfig", "PSFramework", "SetPSFConfigCommand.cs", 0, null, EnableException.ToBool());
                return;
            }
        }

        private void ExecuteNewPersisted()
        {
            _Config = new Config();
            _Config.Name = _NameName;
            _Config.Module = _NameModule;
            _Config.SetPersistedValue(PersistedType, PersistedValue);
            ApplyCommonSettings();
            ConfigurationHost.Configurations[_NameFull] = _Config;
        }

        private void ExecuteUpdatePersisted()
        {
            if (_PolicyEnforced)
            {
                StopCommand($"Could not update configuration: {_NameFull} - The current settings have been enforced by policy!", null, _NameFull, "Set-PSFConfig", "PSFramework", "SetPSFConfigCommand.cs", 0, null, EnableException.ToBool());
                return;
            }

            _Config.SetPersistedValue(PersistedType, PersistedValue);
            ApplyCommonSettings();
            ConfigurationHost.Configurations[_NameFull] = _Config;
        }

        /// <summary>
        /// Applies a value to a configuration item, invoking validation and handler scriptblocks.
        /// </summary>
        /// <param name="Value">The value to apply</param>
        private void ApplyValue(object Value)
        {
            object tempValue = Value;

            #region Validation
            if (!DisableValidation.ToBool() && (_Config.Validation != null))
            {
                PSObject validationResult = _Config.Validation.InvokeEx(true, tempValue, tempValue, null, true, true, new object[] { tempValue })[0];
                if (!(bool)validationResult.Properties["Success"].Value)
                {
                    _ValidationErrorMessage = (string)validationResult.Properties["Message"].Value;
                    throw new ArgumentException(String.Format("Failed validation: {0}", _ValidationErrorMessage));
                }
                tempValue = validationResult.Properties["Value"].Value;
            }
            #endregion Validation

            #region Handler
            if (!DisableHandler.ToBool() && (_Config.Handler != null))
            {
                object handlerValue = tempValue;
                if ((tempValue != null) && ((tempValue as ICollection) != null))
                    handlerValue = new object[1] { tempValue };

                _Config.Handler.InvokeEx(true, handlerValue, handlerValue, null, true, true, new object[] { handlerValue });
            }
            #endregion Handler

            _Config.Value = tempValue;
        }

        /// <summary>
        /// Abstracts out the regular settings that keep getting applied
        /// </summary>
        private void ApplyCommonSettings()
        {
            if (!String.IsNullOrEmpty(Description))
                _Config.Description = Description;
            if (Handler != null)
                _Config.Handler = Handler;
            if (!String.IsNullOrEmpty(Validation))
                _Config.Validation = ConfigurationHost.Validation[Validation];
            if (Hidden.IsPresent)
                _Config.Hidden = Hidden;
            if (SimpleExport.IsPresent)
                _Config.SimpleExport = SimpleExport.ToBool();
            if (ModuleExport.IsPresent)
                _Config.ModuleExport = ModuleExport.ToBool();
            // Will be silently ignored if the setting is already initialized.
            if (AllowDelete.IsPresent)
                _Config.AllowDelete = AllowDelete.ToBool();
        }
        #endregion Private Methods
    }
}
