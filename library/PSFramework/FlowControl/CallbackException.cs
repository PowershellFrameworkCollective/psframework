using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.FlowControl
{
    /// <summary>
    /// A custom exception, including the callback that failed
    /// </summary>
    public class CallbackException : Exception
    {
        /// <summary>
        /// The callback that failed
        /// </summary>
        public Callback Callback;

        /// <summary>
        /// Creates a new callback exception, including the Callback that failed
        /// </summary>
        /// <param name="Callback">The callback that failed</param>
        /// <param name="InnerException">The exception it failed with</param>
        public CallbackException(Callback Callback, Exception InnerException)
            : base(InnerException.Message, InnerException)
        {
            this.Callback = Callback;
        }
    }
}
