using System;
using PSFramework.PSFCore;

namespace PSFramework.Temp
{
    /// <summary>
    /// A temporary item
    /// </summary>
    public abstract class TempItem
    {
        /// <summary>
        /// What kind of item is this?
        /// </summary>
        public abstract TempItemType Type { get; }

        /// <summary>
        /// Does the item still exist?
        /// </summary>
        public abstract bool Exists { get; }

        /// <summary>
        /// When will this temporary item expire?
        /// </summary>
        public DateTime Timeout;

        /// <summary>
        /// Name of the item
        /// </summary>
        public string Name;

        /// <summary>
        /// The module that owns the item
        /// </summary>
        public string Module;

        /// <summary>
        /// Remove the temporary item. Must remove itself from the Parent's list once completed.
        /// </summary>
        public abstract void Delete();

        /// <summary>
        /// Parent container
        /// </summary>
        internal TempItemContainer Parent;

        internal void WriteMessage(string Message)
        {
            PSFCoreHost.WriteDebug(Message, null);
        }
        internal void WriteError(string Message, object Error)
        {
            PSFCoreHost.WriteDebug(Message, Error);
            LastError = Error;
        }

        /// <summary>
        /// The last error that happened to the TempItem.
        /// Usually errors when trying to run Delete()
        /// </summary>
        public object LastError;

        /// <summary>
        /// String representation of this object
        /// </summary>
        /// <returns>some text</returns>
        public override string ToString()
        {
            return $"{Type}: {Module}>{Name}";
        }
    }
}
