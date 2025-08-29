using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

using PSFramework.Meta;
using PSFramework.TabExpansion;

namespace PSFramework.Commands
{
    /// <summary>
    /// Imports provided values to parameters configured for an auto-training completer.
    /// </summary>
    [Cmdlet(VerbsData.Update, "PSFTeppCompletion")]
    public class UpdatePSFTeppCompletionCommand : PSFCmdlet
    {
        /// <summary>
        /// Execute the main (and only) step: Copying over values provided to the calling command as parameter into the completion cache.
        /// Only applies to parameters configured for auto-training tab completers.
        /// </summary>
        protected override void ProcessRecord()
        {
            CallStackFrame caller = GetCaller();
            foreach (var pair in caller.InvocationInfo.BoundParameters)
            {
                // If the parameter does not exist, something weird is happening and we want no part in it
                if (!caller.InvocationInfo.MyCommand.Parameters.ContainsKey(pair.Key))
                    continue;

                PsfArgumentCompleterAttribute attribute = (PsfArgumentCompleterAttribute)caller.InvocationInfo.MyCommand.Parameters[pair.Key].Attributes.Where(o => o.TypeId.ToString() == "PSFramework.TabExpansion.PsfArgumentCompleterAttribute").FirstOrDefault();
                // Without our Argument Completer attribute, there is nothing to cache
                if (attribute == null || attribute.CompletionName == "")
                    continue;

                // Do not cache if completer does not exist or is not configured to autocache
                if (!TabExpansionHost.Scripts.ContainsKey(attribute.CompletionName) || !TabExpansionHost.Scripts[attribute.CompletionName].AutoTraining)
                    continue;

                // Do not cache empty values
                if (pair.Value == null)
                    continue;

                string converted = LanguagePrimitives.ConvertTo<string>(pair.Value);

                // Do not cache values that resolve to empty-string or their typename
                if (String.IsNullOrEmpty(converted) || converted == pair.Value.GetType().FullName)
                    continue;

                TabExpansionHost.Scripts[attribute.CompletionName].AddTraining(converted);
            }
        }
    }
}
