class CfgFunctions 
{
    class A3A
    {
        class AI
        {
            class fastrope
            {
                file = QPATHTOFOLDER(AI\fn_fastrope.sqf);
            };
            class fastropeVTOL
            {
                file = QPATHTOFOLDER(AI\fn_fastropeVTOL.sqf);
            };
            class paradrop
            {
                file = QPATHTOFOLDER(AI\fn_paradrop.sqf);
            };
        };

        /* class init 
        {
            class initServer 
            {
                file = QPATHTOFOLDER(init\fn_initClient.sqf);
            };
            class initClient 
            {
                file = QPATHTOFOLDER(init\fn_initServer.sqf);
            };
        }; */
    };
    //your own functions should be kept here
    class ADDON
    {
        class Events 
        { //these two functions are used to demonstrate use of events
            file = QPATHTOFOLDER(Events);
            class addExampleEventListener { postInit = 1; };
            class AIVehInit {};
        };
    };
};
