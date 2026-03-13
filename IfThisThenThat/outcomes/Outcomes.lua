local IFTTT = IfThisThenThat

local Outcomes = IFTTT.Outcomes or ZO_DeferredInitializingObject:Subclass()

function IFTTT.Outcomes:Initialize(parent)
  self.items = {}
  self.parent = parent
end

function Outcomes.Initialize( ... )
	IFTTT.CV.Outcomes = Outcomes:New( ... )
end
