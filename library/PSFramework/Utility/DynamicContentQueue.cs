using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// A dynamic content object that implements a queue
    /// </summary>
    public class DynamicContentQueue : DynamicContentObject
    {
        public DynamicContentQueue(string Name, object Value)
            : base(Name, Value)
        {

        }
    }
}
