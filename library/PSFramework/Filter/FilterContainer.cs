using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Filter
{
    /// <summary>
    /// A container object designed to hold all the stored conditions and condition sets included in a runspace.
    /// </summary>
    public class FilterContainer
    {
        /// <summary>
        /// Returns the filter data for the current runspace.
        /// </summary>
        public static FilterContainer Filters
        {
            get
            {
                if (_Filters.Value == null)
                    _Filters.Value = new FilterContainer();
                return _Filters.Value;
            }
        }
        private static Runspace.RunspaceBoundValueGeneric<FilterContainer> _Filters = new Runspace.RunspaceBoundValueGeneric<FilterContainer>(null, false);

        Dictionary<string, ModuleWrapper> Content = new Dictionary<string, ModuleWrapper>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Retrieve registered conditions based on the information provided
        /// </summary>
        /// <param name="Module">The modulename to filter by.</param>
        /// <param name="Name">The condition name to filter by.</param>
        /// <param name="Version">The version number to select.</param>
        /// <param name="AllVersions">Return all versions of a given condition</param>
        /// <returns>All conditions matching the search criteria.</returns>
        public List<Condition> FindCondition(string Module = "*", string Name = "*", Version Version = null, bool AllVersions = false)
        {
            List<Condition> conditions = new List<Condition>();
            foreach (ModuleWrapper module in Content.Values.Where(o => UtilityHost.IsLike(o.Name, Module)))
                if (AllVersions)
                    conditions.AddRange(module.ListCondition().Where(o => UtilityHost.IsLike(o.Name, Name)));
                else if (Version != null)
                    conditions.AddRange(module.ListCondition().Where(o => UtilityHost.IsLike(o.Name, Name) && o.Version == Version));
                else
                    foreach (ConditionWrapper conditionWrapper in module.Conditions.Values.Where(o => UtilityHost.IsLike(o.Name, Name)))
                        conditions.Add(conditionWrapper.Get());
            return conditions;
        }

        /// <summary>
        /// Retrieve registered conditions based on the information provided
        /// </summary>
        /// <param name="Module">The modulename to filter by.</param>
        /// <param name="Name">The condition name to filter by.</param>
        /// <param name="Version">The version number to select.</param>
        /// <param name="AllVersions">Return all versions of a given condition</param>
        /// <returns>All conditions matching the search criteria.</returns>
        public List<Condition> GetCondition(string Module, string Name, Version Version = null, bool AllVersions = false)
        {
            if (!Content.ContainsKey(Module))
                return null;

            List<Condition> conditions = new List<Condition>();
            ModuleWrapper module = Content[Module];
            if (!module.Conditions.ContainsKey(Name))
                return null;
            ConditionWrapper conditionWrapper = module.Conditions[Name];
            
            if (AllVersions)
                conditions.AddRange(conditionWrapper.List());
            else if (Version != null)
                conditions.Add(conditionWrapper.Get(Version));
            else
                conditions.Add(conditionWrapper.Get());
            return conditions;
        }

        /// <summary>
        /// Retrieve registered condition sets based on the information provided
        /// </summary>
        /// <param name="Module">The modulename to filter by.</param>
        /// <param name="Name">The conditionset name to filter by.</param>
        /// <param name="Version">The version number to select.</param>
        /// <param name="AllVersions">Return all versions of a given conditionset</param>
        /// <returns>All condition sets matching the search criteria.</returns>
        public List<ConditionSet> FindConditionSet(string Module = "*", string Name = "*", Version Version = null, bool AllVersions = false)
        {
            List<ConditionSet> conditionSets = new List<ConditionSet>();
            foreach (ModuleWrapper module in Content.Values.Where(o => UtilityHost.IsLike(o.Name, Module)))
                if (AllVersions)
                    conditionSets.AddRange(module.ListConditionSet().Where(o => UtilityHost.IsLike(o.Name, Name)));
                else if (Version != null)
                    conditionSets.AddRange(module.ListConditionSet().Where(o => UtilityHost.IsLike(o.Name, Name) && o.Version == Version));
                else
                    foreach (ConditionSetWrapper conditionSetWrapper in module.ConditionSets.Values.Where(o => UtilityHost.IsLike(o.Name, Name)))
                        conditionSets.Add(conditionSetWrapper.Get());
            return conditionSets;
        }

        /// <summary>
        /// Retrieve registered condition sets based on the information provided
        /// </summary>
        /// <param name="Module">The modulename to select.</param>
        /// <param name="Name">The condition name to select.</param>
        /// <param name="Version">The version number to select.</param>
        /// <param name="AllVersions">Return all versions of a given condition</param>
        /// <returns>All conditions matching the search criteria.</returns>
        public List<ConditionSet> GetConditionSet(string Module, string Name, Version Version = null, bool AllVersions = false)
        {
            if (!Content.ContainsKey(Module))
                return null;

            List<ConditionSet> conditionSets = new List<ConditionSet>();
            ModuleWrapper module = Content[Module];
            if (!module.ConditionSets.ContainsKey(Name))
                return null;
            ConditionSetWrapper conditionSetWrapper = module.ConditionSets[Name];

            if (AllVersions)
                conditionSets.AddRange(conditionSetWrapper.List());
            else if (Version != null)
                conditionSets.Add(conditionSetWrapper.Get(Version));
            else
                conditionSets.Add(conditionSetWrapper.Get());
            return conditionSets;
        }

        /// <summary>
        /// Create a new condition.
        /// </summary>
        /// <param name="Name">Name of the condition</param>
        /// <param name="Module">Name of the module owning the condition</param>
        /// <param name="ScriptBlock">The scriptblock that evaluates the condition</param>
        /// <param name="Version">The version of the condition</param>
        /// <param name="Type">The type of the condition</param>
        /// <returns>The newly created condition</returns>
        public Condition AddCondition(string Module, string Name, PsfScriptBlock ScriptBlock, Version Version = null, ConditionType Type = ConditionType.Dynamic)
        {
            if (Version == null)
                Version = new Version(1, 0, 0);
            if (!Content.ContainsKey(Module))
                Content[Module] = new ModuleWrapper(Module);
            Condition newCondition = new Condition(Name, Module, ScriptBlock, Version, Type);
            Content[Module].Add(newCondition);
            return newCondition;
        }

        /// <summary>
        /// Create a new condition set
        /// </summary>
        /// <param name="Name">Name of the set</param>
        /// <param name="Module">Module under which the condition set is defined</param>
        /// <param name="Version">Version of the set</param>
        /// <param name="Conditions">Conditions to include in the set.</param>
        /// <returns>The newly created condition set</returns>
        public ConditionSet AddConditionSet(string Module, string Name, Version Version = null, List<Condition> Conditions = null)
        {
            if (Version == null)
                Version = new Version(1, 0, 0);
            if (Conditions == null)
                Conditions = new List<Condition>();
            if (!Content.ContainsKey(Module))
                Content[Module] = new ModuleWrapper(Module);
            ConditionSet newConditionSet = new ConditionSet(Name, Module, Version, Conditions);
            Content[Module].Add(newConditionSet);
            return newConditionSet;
        }

        /// <summary>
        /// Create a new condition set
        /// </summary>
        /// <param name="Name">Name of the set</param>
        /// <param name="Module">Module under which the condition set is defined</param>
        /// <param name="Version">Version of the set</param>
        /// <param name="Conditions">Conditions to include in the set.</param>
        /// <returns>The newly created condition set</returns>
        public ConditionSet AddConditionSet(string Module, string Name, Version Version = null, Condition[] Conditions = null)
        {
            return AddConditionSet(Module, Name, Version, new List<Condition>(Conditions));
        }
    }
}
