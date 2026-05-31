using PSFramework.Parameter;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    public class RSWorkItem
    {
        public object Item;

        public RSTimeout TimeoutType = RSTimeout.Undefined;
        
        public TimeSpanParameter Timeout;

        public int RetryCount;

        public RSWorkItem(object Item)
        {
            this.Item = Item;
        }
    }
}
