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
    public class DynamicContentDictionary : DynamicContentObject
    {
        /// <summary>
        /// The value of the dynamic content object
        /// </summary>
        public new object Value
        {
            get { return _Dictionary; }
            set
            {
                if (value == null)
                    _Dictionary = new ConcurrentDictionary<string,object>(StringComparer.InvariantCultureIgnoreCase);
                else if ((value as ConcurrentDictionary<string, object>) != null)
                    _Dictionary = value as ConcurrentDictionary<string, object>;
                else
                    throw new ArgumentException("Only accepts concurrent dictionary. Specify a null value to reset or queue to add items!");
            }
        }
        private ConcurrentDictionary<string, object> _Dictionary = new ConcurrentDictionary<string, object>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Creates a dynamic content object concurrent dictionary 
        /// </summary>
        /// <param name="Name">The name of the setting</param>
        /// <param name="Value">The initial value of the object</param>
        public DynamicContentDictionary(string Name, object Value)
            : base(Name, Value)
        {

        }

        /// <summary>
        /// Resets the stack by reestablishing an empty dictionary.
        /// </summary>
        public void Reset()
        {
            _Dictionary = new ConcurrentDictionary<string, object>(StringComparer.InvariantCultureIgnoreCase);
        }
    }
}
