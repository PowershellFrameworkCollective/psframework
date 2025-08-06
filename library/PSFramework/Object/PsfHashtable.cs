using System;
using System.Collections;
using System.Management.Automation;
using PSFramework.Extension;

namespace PSFramework.Object
{
    /// <summary>
    /// Extend default hashtables to include a default value
    /// </summary>
    public class PsfHashtable : Hashtable
    {
        /// <summary>
        /// The default value when retrieving values for keys that do not exist
        /// </summary>
        private object defaultValue;

        /// <summary>
        /// Whether in case of unexpected key, the key should be returned, rather than a default value.
        /// </summary>
        private bool passThru;

        /// <summary>
        /// Scriptblock used to calculate result when providing a key that is not applied to the hashtable.
        /// </summary>
        private ScriptBlock calculator;

        /// <summary>
        /// Creates a new, empty psfhashtable
        /// </summary>
        public PsfHashtable()
            :base(StringComparer.OrdinalIgnoreCase)
        {

        }

        /// <summary>
        /// Creates a new PsfHashtable based on an existing hashtable
        /// </summary>
        /// <param name="Original"></param>
        public PsfHashtable(Hashtable Original)
            : base(StringComparer.OrdinalIgnoreCase)
        {
            foreach (object key in Original.Keys)
                this[key] = Original[key];
        }

        /// <summary>
        /// Set the default value provided, when reading for a key that does not yet exist.
        /// </summary>
        /// <param name="Value">The default value when accessing this PsfHashtable's values</param>
        public void SetDefaultValue(object Value)
        {
            defaultValue = Value;
        }

        /// <summary>
        /// Enables the PassThru behavior, where an unexpected key gets returned as the default action
        /// </summary>
        public void EnablePassthru()
            { passThru = true; }

        /// <summary>
        /// Disables the PassThru behavior, where an unexpected key would get returned as the default action
        /// </summary>
        public void DisablePassThru()
            { passThru = false; }

        /// <summary>
        /// Sets the scriptblock used to calculate the results for keys, that are not registered with the hashtable
        /// </summary>
        /// <param name="Calculator">The logic doing the calculating. Provide null to disable.</param>
        public void SetCalculator(ScriptBlock Calculator)
            { this.calculator = Calculator; }

        /// <summary>
        /// Create a copy of the current PsfHashtable, including its default value. The default value will be the same instance of an object.
        /// </summary>
        /// <returns>A copy of the current PsfHashtable.</returns>
        public override object Clone()
        {
            PsfHashtable temp = (PsfHashtable)base.Clone();
            temp.SetDefaultValue(defaultValue);
            if (passThru)
                temp.EnablePassthru();
            return temp;
        }

        /// <summary>
        /// The overriden read/write accessor for entries in this extended hashtable.
        /// Reads will return the default value when the key does not exist.
        /// </summary>
        /// <param name="key">The key of the value to read or write.</param>
        /// <returns>The value behind the key specified or the default value if none exists.</returns>
        public override object this[object key]
        {
            get
            {
                if (!ContainsKey(key))
                {
                    if (calculator != null)
                        return calculator.DoInvokeReturnAsIs(false, 2, key, key, this, new object[] { key });
                    if (passThru)
                        return key;
                    return defaultValue;
                }
                return base[key];
            }
            set => base[key] = value;
        }
    }
}
