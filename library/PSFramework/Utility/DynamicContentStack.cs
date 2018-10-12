using System;
using System.Collections.Concurrent;

namespace PSFramework.Utility
{
    /// <summary>
    /// A dynamic content object that implements a stack
    /// </summary>
    public class DynamicContentStack : DynamicContentObject
    {
        /// <summary>
        /// The value of the dynamic content object
        /// </summary>
        public new object Value
        {
            get { return _Stack; }
            set
            {
                if (value == null)
                    _Stack = new ConcurrentStack<object>();
                else if ((Value as ConcurrentStack<object>) != null)
                    _Stack = Value as ConcurrentStack<object>;
                else
                    throw new ArgumentException("Only accepts concurrent stacks. Specify a null value to reset or queue to add items!");
            }
        }
        private ConcurrentStack<object> _Stack = new ConcurrentStack<object>();

        /// <summary>
        /// Creates a dynamic content object concurrent stack 
        /// </summary>
        /// <param name="Name">The name of the setting</param>
        /// <param name="Value">The initial value of the object</param>
        public DynamicContentStack(string Name, object Value)
            : base(Name, Value)
        {

        }

        /// <summary>
        /// How many items are currently stacked
        /// </summary>
        public int Count
        {
            get { return _Stack.Count; }
        }

        /// <summary>
        /// Returns the current stack content as array
        /// </summary>
        /// <returns>The current queue content</returns>
        public object[] ToArray()
        {
            return _Stack.ToArray();
        }

        /// <summary>
        /// Adds an item to the stack
        /// </summary>
        /// <param name="Item">The item to add</param>
        public void Push(object Item)
        {
            _Stack.Push(Item);
        }

        /// <summary>
        /// Returns an object if there is anything to take from the stack
        /// </summary>
        /// <returns>The next queued item</returns>
        public object Pop()
        {
            object value;
            _Stack.TryPop(out value);
            return value;
        }

        /// <summary>
        /// Resets the stack by reestablishing an empty stack.
        /// </summary>
        public void Reset()
        {
            Value = new ConcurrentStack<object>();
        }
    }
}
