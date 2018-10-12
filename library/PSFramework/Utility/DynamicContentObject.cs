using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;

namespace PSFramework.Utility
{
    /// <summary>
    /// Class that contains a value that can be updated from another runspace
    /// </summary>
    public class DynamicContentObject
    {
        #region Statics
        /// <summary>
        /// The full dictionary of dynamic objects
        /// </summary>
        private static Dictionary<string, DynamicContentObject> Values = new Dictionary<string, DynamicContentObject>(StringComparer.InvariantCultureIgnoreCase);
        
        /// <summary>
        /// List of all dynamic content objects registered
        /// </summary>
        public static string[] List
        {
            get { return Values.Keys.ToArray(); }
        }

        /// <summary>
        /// Sets the value of a dynamic content object, creating a new one if needed
        /// </summary>
        /// <param name="Name">The name of the object</param>
        /// <param name="Value">The value to set</param>
        /// <param name="Type">The type of dynamic content object to create (if creatable)</param>
        public static void Set(string Name, object Value, DynamicContentObjectType Type = DynamicContentObjectType.Common)
        {
            if (Values.ContainsKey(Name))
                Values[Name].Value = Value;
            else
            {
                switch (Type)
                {
                    case DynamicContentObjectType.Dictionary:
                        Values[Name] = new DynamicContentDictionary(Name, Value);
                        break;
                    case DynamicContentObjectType.List:
                        Values[Name] = new DynamicContentList(Name, Value);
                        break;
                    case DynamicContentObjectType.Queue:
                        Values[Name] = new DynamicContentQueue(Name, Value);
                        break;
                    case DynamicContentObjectType.Stack:
                        Values[Name] = new DynamicContentStack(Name, Value);
                        break;
                    default:
                        Values[Name] = new DynamicContentObject(Name, Value);
                        break;
                }
            }
        }

        /// <summary>
        /// Returns the Dynamic Content Object under the specified name
        /// </summary>
        /// <param name="Name">The name of the object to return</param>
        /// <returns>The Dynamic Content Object selected</returns>
        public static DynamicContentObject Get(string Name)
        {
            if (!Values.ContainsKey(Name))
                Values[Name] = new DynamicContentObject(Name, null);

            return Values[Name];
        }
        #endregion Statics

        #region object properties
        /// <summary>
        /// The value stored in this object
        /// </summary>
        public object Value;

        /// <summary>
        /// The name of the object
        /// </summary>
        public string Name;

        /// <summary>
        /// Turns the value into a concurrent queue.
        /// </summary>
        public void ConcurrentQueue(bool Reset = false)
        {
            if (Value == null || Reset)
                Value = new ConcurrentQueue<object>();
            else if (!UtilityHost.IsLike(Value.GetType().FullName, "System.Collections.Concurrent.ConcurrentQueue*"))
                Value = new ConcurrentQueue<object>();
        }

        /// <summary>
        /// Turns the value into a concurrent stack
        /// </summary>
        public void ConcurrentStack(bool Reset = false)
        {
            if (Value == null || Reset)
                Value = new ConcurrentStack<object>();
            else if (!UtilityHost.IsLike(Value.GetType().FullName, "System.Collections.Concurrent.ConcurrentStack*"))
                Value = new ConcurrentStack<object>();
        }

        /// <summary>
        /// Turns the value into a concurrent list
        /// </summary>
        public void ConcurrentList(bool Reset = false)
        {
            if (Value == null || Reset)
                Value = new BlockingCollection<object>();
            else if (!UtilityHost.IsLike(Value.GetType().FullName, "System.Collections.Concurrent.BlockingCollection*"))
                Value = new BlockingCollection<object>();
        }

        /// <summary>
        /// TUrns the value into a concurrent dictionary with case-insensitive string keys
        /// </summary>
        public void ConcurrentDictionary(bool Reset = false)
        {
            if (Value == null || Reset)
                Value = new ConcurrentDictionary<string, object>(StringComparer.InvariantCultureIgnoreCase);
            else if (!UtilityHost.IsLike(Value.GetType().FullName, "System.Collections.Concurrent.ConcurrentDictionary*"))
                Value = new ConcurrentDictionary<string, object>(StringComparer.InvariantCultureIgnoreCase);
        }

        /// <summary>
        /// General string representation of the value
        /// </summary>
        /// <returns>The string representation of the value</returns>
        public override string ToString()
        {
            return Value.ToString();
        }

        /// <summary>
        /// Creates a named value object that can be updated in the background
        /// </summary>
        /// <param name="Name">The name of the item</param>
        /// <param name="Value">The value of the item</param>
        public DynamicContentObject(string Name, object Value)
        {
            this.Value = Value;
            this.Name = Name.ToLower();

            Values[Name.ToLower()] = this;
        }
        #endregion object properties
    }
}
