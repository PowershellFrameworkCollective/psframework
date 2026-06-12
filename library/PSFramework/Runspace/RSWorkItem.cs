using PSFramework.Parameter;
using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// An object to process by the runspace workflow
    /// </summary>
    public class RSWorkItem
    {
        /// <summary>
        /// The entry to process
        /// </summary>
        public object Item;

        /// <summary>
        /// How to handle timeout during processing.
        /// </summary>
        public RSTimeout TimeoutType = RSTimeout.Undefined;
        
        /// <summary>
        /// The timeout to apply
        /// </summary>
        public TimeSpanParameter Timeout;

        /// <summary>
        /// How many times to attempt processing this object in case of error
        /// </summary>
        public Nullable<int> RetryCount;

        /// <summary>
        /// Condition under which the item should be attempted again
        /// </summary>
        public PsfScriptBlock RetryCondition;

        /// <summary>
        /// Creates a new runspace workflow work item
        /// </summary>
        /// <param name="Item">The object to process</param>
        public RSWorkItem(object Item)
        {
            this.Item = Item;
        }
    }
}
