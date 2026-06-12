using PSFramework.Caching;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// A dynamic content object that implements a dictionary
    /// </summary>
    public class DynamicContentCache : DynamicContentObject
    {
        /// <summary>
        /// The value of the dynamic content object
        /// </summary>
        public new object Value
        {
            get { return _Cache; }
            set
            {
                if (value == null)
                    _Cache = new CacheMemoryConcurrent();
                else if ((value as CacheMemoryConcurrent) != null)
                    _Cache = value as CacheMemoryConcurrent;
                else
                    throw new ArgumentException("Only accepts PSFramework Cache (Memory, Concurrent) objects. Specify a null value to reset or queue to add items!");
            }
        }
        private CacheMemoryConcurrent _Cache = new CacheMemoryConcurrent();

        /// <summary>
        /// Creates a dynamic content object concurrent dictionary 
        /// </summary>
        /// <param name="Name">The name of the setting</param>
        /// <param name="Value">The initial value of the object</param>
        public DynamicContentCache(string Name, object Value)
            : base(Name, Value)
        {

        }

        /// <summary>
        /// Resets the stack by reestablishing an empty dictionary.
        /// </summary>
        public void Reset()
        {
            _Cache = new CacheMemoryConcurrent();
        }
    }
}
