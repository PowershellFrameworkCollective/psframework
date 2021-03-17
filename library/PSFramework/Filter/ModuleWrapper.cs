using System;
using System.Collections.Generic;

namespace PSFramework.Filter
{
    internal class ModuleWrapper
    {
        internal string Name;

        internal Dictionary<string, ConditionWrapper> Conditions = new Dictionary<string, ConditionWrapper>(StringComparer.InvariantCultureIgnoreCase);
        internal Dictionary<string, ConditionSetWrapper> ConditionSets = new Dictionary<string, ConditionSetWrapper>(StringComparer.InvariantCultureIgnoreCase);

        internal ModuleWrapper(string Name)
        {
            this.Name = Name;
        }

        internal void Add(Condition Condition)
        {
            if (!Conditions.ContainsKey(Condition.Name))
                Conditions[Condition.Name] = new ConditionWrapper(Condition);
            else
                Conditions[Condition.Name].Add(Condition);
        }

        internal void Add(ConditionSet ConditionSet)
        {
            if (!ConditionSets.ContainsKey(ConditionSet.Name))
                ConditionSets[ConditionSet.Name] = new ConditionSetWrapper(ConditionSet);
            else
                ConditionSets[ConditionSet.Name].Add(ConditionSet);
        }

        internal Condition GetCondition(string Name)
        {
            if (!Conditions.ContainsKey(Name))
                return null;
            return Conditions[Name].Get();
        }
        internal Condition GetCondition(string Name, Version Version)
        {
            if (!Conditions.ContainsKey(Name))
                return null;
            return Conditions[Name].Get(Version);
        }
        internal List<Condition> ListCondition()
        {
            List<Condition> conditions = new List<Condition>();
            foreach (ConditionWrapper wrapper in Conditions.Values)
                conditions.AddRange(wrapper.List());
            return conditions;
        }

        internal ConditionSet GetConditionSet(string Name)
        {
            if (!ConditionSets.ContainsKey(Name))
                return null;
            return ConditionSets[Name].Get();
        }
        internal ConditionSet GetConditionSet(string Name, Version Version)
        {
            if (!ConditionSets.ContainsKey(Name))
                return null;
            return ConditionSets[Name].Get(Version);
        }
        internal List<ConditionSet> ListConditionSet()
        {
            List<ConditionSet> conditionSets = new List<ConditionSet>();
            foreach (ConditionSetWrapper wrapper in ConditionSets.Values)
                conditionSets.AddRange(wrapper.List());
            return conditionSets;
        }
    }
}
