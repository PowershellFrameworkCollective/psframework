using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// A scriptblock container item
    /// </summary>
    public class ScriptBlockItem
    {
        /// <summary>
        /// Name of the scriptblock
        /// </summary>
        public string Name;

        /// <summary>
        /// The scriptblock stored
        /// </summary>
        public ScriptBlock ScriptBlock
        {
            get
            {
                CountRetrieved++;
                LastRetrieved = DateTime.Now;
                return _ScriptBlock;
            }
            set { _ScriptBlock = value; }
        }
        private PsfScriptBlock _ScriptBlock
        {
            get
            {
                if (!Local)
                    return _GlobalScriptBlock;
                return _LocalScriptBlock?.Value;
            }
            set
            {
                _GlobalScriptBlock = value;
                if (null == _LocalScriptBlock)
                    _LocalScriptBlock = new Runspace.RunspaceBoundValueGeneric<PsfScriptBlock>(value, false);
                _LocalScriptBlock.Value = value;
            }
        }

        private PsfScriptBlock _GlobalScriptBlock;
        private Runspace.RunspaceBoundValueGeneric<PsfScriptBlock> _LocalScriptBlock;

        /// <summary>
        /// Checks, whether the scriptblock is available in a given runspace.
        /// </summary>
        /// <returns>whether the scriptblock is available in the current runspace</returns>
        public bool IsAvailable()
        {
            if (!Local)
                return true;
            return _ScriptBlock?.ScriptBlock != null;
        }

        /// <summary>
        /// Whether the scriptblock should be invoked as global scriptblock
        /// </summary>
        public bool Global;

        /// <summary>
        /// Whether the scriptblock is local to its respective runspace.
        /// If set to true, each scriptblock will be unavailable to any runspace other than the one that defined it.
        /// However, each runspace can define its own instance of a given scriptblock.
        /// </summary>
        public bool Local;

        /// <summary>
        /// The number of times this scriptblock has been used
        /// </summary>
        public int CountRetrieved { get; private set; }

        /// <summary>
        /// When the scriptblock has last been used
        /// </summary>
        public DateTime LastRetrieved { get; private set; }

        /// <summary>
        /// A list of tags so the scriptblock can be found
        /// </summary>
        public List<string> Tag {get; set;}

        /// <summary>
        /// Full-text description of the scriptblock
        /// </summary>
        public string Description {get; set;}

        /// <summary>
        /// Create a new scriptblock item by offering both name and code
        /// </summary>
        /// <param name="Name">The name of the scriptblock</param>
        /// <param name="ScriptBlock">The scriptblock</param>
        /// <param name="Global">Whether the scriptblock should be invoked as global scriptblock</param>
        /// <param name="Local">Whether the scriptblock is local to the current runspace only</param>
        /// <param name="Tag">An optional list of tags</param>
        /// <param name="Description">An optional description</param>
        public ScriptBlockItem(string Name, ScriptBlock ScriptBlock, bool Global = false, bool Local = false, List<string> Tag = null, string Description = "")
        {
            this.Name = Name;
            this.Local = Local;
            this.Global = Global;
            this.Tag = null == Tag ? new List<string>() : Tag;
            this.Description = Description;
            this.ScriptBlock = ScriptBlock;
        }



        #region Invocation
        /// <summary>
        /// Invoke the Scriptblock rehomed to the global scope
        /// </summary>
        /// <param name="Value">The value - if any - to offer as argument / input for the scriptblock</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public Collection<PSObject> InvokeGlobal(object Value = null)
        {
            return ((PsfScriptBlock)ScriptBlock).InvokeGlobal(Value);
        }
        /// <summary>
        /// Invoke the Scriptblock as configured
        /// </summary>
        /// <param name="args">The value - if any - to offer as argument for the scriptblock</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public Collection<PSObject> Invoke(params object[] args)
        {
            if (Global)
                return ((PsfScriptBlock)ScriptBlock).InvokeEx(true, null, null, null, true, true, args);
            return ((PsfScriptBlock)ScriptBlock).InvokeEx(true, null, null, null, false, false, args);
        }

        /// <summary>
        /// Do a rich invocation of the scriptblock
        /// </summary>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="DollerUnder">The value to make available as $_</param>
        /// <param name="Input">The value to make available to $input</param>
        /// <param name="ScriptThis">The value to make available as $this</param>
        /// <param name="ImportContext">Whether to first import the scriptblock into the current Context.</param>
        /// <param name="ImportGlobal">When importing the ScriptBlock, import it into the global Context instead.</param>
        /// <param name="Args">The value to make available as $args</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public Collection<PSObject> InvokeEx(bool UseLocalScope, object DollerUnder, object Input, object ScriptThis, bool ImportContext, bool ImportGlobal, params object[] Args)
        {
            return ((PsfScriptBlock)ScriptBlock).InvokeEx(UseLocalScope, DollerUnder, Input, ScriptThis, ImportContext, ImportGlobal, Args);
        }

        /// <summary>
        /// Do a rich invocation of the scriptblock
        /// </summary>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="ImportContext">Whether to first import the scriptblock into the current Context.</param>
        /// <param name="ImportGlobal">When importing the ScriptBlock, import it into the global Context instead.</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public Collection<PSObject> InvokeEx(bool UseLocalScope, bool ImportContext, bool ImportGlobal)
        {
            return InvokeEx(UseLocalScope, null, null, null, ImportContext, ImportGlobal, null);
        }

        /// <summary>
        /// Do a rich invocation of the scriptblock
        /// </summary>
        /// <param name="Value">The value to offer as argument / input for the scriptblock</param>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="ImportContext">Whether to first import the scriptblock into the current Context.</param>
        /// <param name="ImportGlobal">When importing the ScriptBlock, import it into the global Context instead.</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public Collection<PSObject> InvokeEx(object Value, bool UseLocalScope, bool ImportContext, bool ImportGlobal)
        {
            return InvokeEx(UseLocalScope, Value, Value, null, ImportContext, ImportGlobal, Value);
        }

        #endregion Invocation
    }
}
