using System;
using System.Collections;

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
        /// Create a copy of the current PsfHashtable, including its default value. The default value will be the same instance of an object.
        /// </summary>
        /// <returns>A copy of the current PsfHashtable.</returns>
        public override object Clone()
        {
            PsfHashtable temp = (PsfHashtable)base.Clone();
            temp.SetDefaultValue(defaultValue);
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
                    return defaultValue;
                return base[key];
            }
            set => base[key] = value;
        }
    }
}
