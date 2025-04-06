class CfgFunctions
{
	class AR
	{
		class AdvancedRappelling
		{
			file = QPATHTOFOLDER(Scripts\AR_AdvancedRappelling\functions);
			//file="\functions\AR_AdvancedRappelling";
			class advancedRappellingInit
			{
				postInit=1;
			};
		};
	};

	class Dash
	{
		class AdvancedPickupRope
		{
			file = QPATHTOFOLDER(Scripts\AR_AdvancedRappelling\functions);
			class AdvancedPickupRopeInit
			{
				postInit = 1; //1 to call the function upon mission start, after objects are initialized. Passed arguments are ["postInit", didJIP]
			};
		};
	};
};