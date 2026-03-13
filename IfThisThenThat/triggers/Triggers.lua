local IFTTT = IfThisThenThat

local Triggers = IFTTT.Triggers or ZO_DeferredInitializingObject:Subclass()

function IFTTT.Triggers:Initialize(parent)
  self.items = {}
  self.parent = parent
end

function Triggers.Initialize( ... )
	IFTTT.CV.Triggers = Triggers:New( ... )
end
