using PSFramework.Meta;
using PSFramework.Utility;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.FlowControl
{
    /// <summary>
    /// Host class providing statics needed to operate the callback feature.
    /// </summary>
    public static class CallbackHost
    {
        /// <summary>
        /// Grand dictionary of callbacks
        /// </summary>
        internal static ConcurrentDictionary<string, Callback> Callbacks = new ConcurrentDictionary<string, Callback>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Adds a callback item to the list of registered callbacks
        /// </summary>
        /// <param name="Callback">The callback to add</param>
        public static void Add(Callback Callback)
        {
            Callbacks[Callback.Identity] = Callback;
        }

        /// <summary>
        /// Returns a list of callbacks
        /// </summary>
        /// <param name="Name">The name to filter by</param>
        /// <param name="All">Whether also callbacks from other runspaces should be included</param>
        /// <returns>The list of matching callbacks</returns>
        public static List<Callback> Get(string Name, bool All = false)
        {
            List<Callback> callbacks = new List<Callback>();
            foreach (Callback callback in Callbacks.Values)
                if (UtilityHost.IsLike(callback.Name, Name) && (All || callback.Runspace == null || callback.Runspace == System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId))
                    callbacks.Add(callback);
            return callbacks;
        }

        /// <summary>
        /// Removes a given callback from the list of registered callbacks
        /// </summary>
        /// <param name="Callback">The callback object to remove</param>
        public static void Remove(Callback Callback)
        {
            Callback dummy;
            Callbacks.TryRemove(Callback.Identity, out dummy);
        }

        /// <summary>
        /// Removes all callbacks specific to the current runspace. Use this during the shutdown sequence of a runspace.
        /// </summary>
        public static void RemoveRunspaceOwned()
        {
            List<Callback> callbacks = new List<Callback>();
            foreach (Callback callback in Callbacks.Values)
                if (callback.Runspace == System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId)
                    callbacks.Add(callback);
            foreach (Callback callback in callbacks)
                Remove(callback);
        }

        /// <summary>
        /// Invokes the callback scriptblocks that apply to the current scenario
        /// </summary>
        /// <param name="Caller">The object containing the information pertaining to the command calling the command invoking the callback.</param>
        /// <param name="Invoker">The meta object representing the invoking command.</param>
        /// <param name="Data">Extra data that was passed to the event</param>
        public static void Invoke(CallerInfo Caller, PSCmdlet Invoker, object Data)
        {
            foreach (Callback callback in Callbacks.Values)
                if (callback.Applies(Invoker.MyInvocation.MyCommand.ModuleName, Invoker.MyInvocation.MyCommand.Name))
                    callback.Invoke(Caller, Invoker, Data);
        }
    }
}
