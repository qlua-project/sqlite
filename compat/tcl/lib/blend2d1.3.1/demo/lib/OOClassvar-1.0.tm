# OOClassvar - special Tcloo extensions to be used within class definitions
#
#   CLASS_VARS _varName_ ...
#   CLASS_CONSTRUCTOR _script_
#   CLASS_DESTRUCTOR  _script_
#   CLASS_METHOD _methodName_ _args_ _body_
#   CLASS_EXPORT _classMethod_ ...
#   CLASS_UNEXPORT _classMethod_ ...
#   plus
#    # TO DO BETTER ...
#    #   SHARE_CLASS_VARS should be issued from *within* the class, not externally !
#   _class_ SHARE_CLASS_VARS ?_namespace_?
# 
# 2022 - A.Buratti fecit

if 0 {
   Example:
   --------
   oo::class create ABC {
   		CLASS_VARS alfa beta
		CLASS_CONSTRUCTOR {
			set alfa 1.0
			set beta 1.0
		}
		 # class-methods not starting with lower-case letters can be used only internally, unless
		 # they are explicitely exported 
		 # Hints: for internal typemethods add a leading _ (underscore)
		CLASS_METHOD summary {} {
			expr {$alfa+$beta}
		}
			
		variable my ; # just an array for storing the instance variables
		
		constructor {a b} {
			 # this statement MUST be added in the constructor
			 # or methods (including the constructor/destructor)
			 #  won't be able to access class-vars
			USE_CLASS_VARS
			set my(a) $a
			set my(b) $b
		}
		method funk {} {
			expr {$my(a)*$alfa + $my(b)*$beta}
		}
   }
   # -- Usage
   ABC create a0  100 200
   ABC create a1  200 1000
   a0 funk  ;# --> 300
   a1 funk  ;# --> 1200
    # call a class-method
   ABC summary ;# -> 2.0
   
    # Share class-variables in a new namespace
   ABC SHARE_CLASS_VARS ;# no namespace specified --> use the class name
    # get/set a class-variable from the ABC namespace
   info vars ABC::*   ;# ->   ::ABC::alfa  ::ABC::beta
   set ABC::alfa 2.0
    # then calling again the funk method, we get different result
   a0 funk ;# -> 400
   a1 funk ;# -> 1400
   ...
   ABC destroy
    # check ABC namespace has been destroyed
   namespace exists ABC ;# -> 0

}
# =============================================================================

package require Tcl 8.6-
package require TclOO

namespace eval OOClassvar {

	 # get the fully qualified name of the private namespace of class $className
	proc CLASS_NS {className} {
		info object namespace $className
	}

	 # * internal*
	 # create a special metaclass with a special destructor
	 #  to be injected in an existing class.
	 # ( see https://wiki.tcl-lang.org/page/oo::class)
	 # Purpose of this metaclass is to run the CLASS_DESTRUCTOR
	 #  and to remove (if existing) the special namespace sharing 
	 #  the public class-variables
	 #
	 # The original class whose (meta)class was oo::class,
	 #  will be changed to have this (meta)class.
	 #
	 # Therefore, when the class is destroyed, its metaclass destructor
	 #  will be called. 
	 # Since its metaclass is now "classWithClassVars", then this special
	 # destructor is called.
	 #
	 #  N.B.: the classWithClassVars class is not destroyed, simply its destructor is run! 
	oo::class create classWithClassVars {
		superclass ::oo::class
		destructor {
			set thisClass [self]
			
			# run CLASS_DESTRUCTOR
			#  (use catch because __classWitClassVars_destructor could be undefined)
			catch { uplevel [list $thisClass __classWitClassVars_destructor] }
	
			# check if a sharedNS for this class exists and then delete it
			set classNS [OOClassvar::CLASS_NS $thisClass]
			if { [info exists ${classNS}::_sharedNS] } {
				set old_sharedNS [set ${classNS}::_sharedNS]
				namespace delete $old_sharedNS
				unset ${classNS}::_sharedNS  
			}
		}

		 # This method creates a new namespace (named as the same class or nameSpace)
		 #  sharing in it all the class-variables.
		 #  Only the class-variable starting with a lower-case letter will be shared.
		 #
		 # This nameSpace is automatically destroyed when the class is destroyed
		 # or when this command is re-issued for the same class
		 #
		 # If nameSpace is not fully-qualified, it's
		 #  interpreted relative to the caller's context.
		 #
		 # Note that an error is raised if nameSpace exists.
		 #				
#  ATTENZIONE
#  una volta attivato, non e' piu' possibile sharare nuove classvar !!
#  In altre parole,puo' essere attivato solo una volta,  e solo dopo che sono
#  state instanziate le class-var !!
# ..  comunque non mi piace;  
#   deve essere chiamato da dentro la classe,  non DEBVE/PUO' essere chiamato da fuori



		method SHARE_CLASS_VARS { {nameSpace {}} } {
			set thisClass [self]
			if { $nameSpace eq "" } {
				set nameSpace $thisClass
			}
			 # make sure nameSpace be a fully qualified namespace
			 # if not, resolve it based on the caller context
			if { ! [string match "::*" $nameSpace] } {
				set nameSpace [uplevel {namespace current}]::$nameSpace
			}
			
			if { [namespace exists $nameSpace] } {
				error "conflict: cannot create shared namespace \"$nameSpace\": a namespace with that name already exists"
			}
			
			## Internal Note ##
			## the nameSpace name is saved in the private namespace of the class
			##  as "_sharedNS"
			
			 # check if a namespace for this class was already created
			 #  and then delete it.
			set classNS [self namespace]
			if { [info exists ${classNS}::_sharedNS] } {
				set old_sharedNS [set ${classNS}::_sharedNS]
				namespace delete $old_sharedNS
				unset ${classNS}::_sharedNS  
			}
				
			 # create the new nameSpace and 'upvar' the class-variables
			 #  in the new nameSpace
			 #  (only for variables starting with a lower-case letter)
			namespace eval $nameSpace {}
		     # note: [info object variable ..] just list the object's-variables
			 # not other injected special variables (like _sharedNS ..). OK
			foreach vname [info object variables $thisClass] {
				if { [string match  {[a-z]*} $vname] } {
					upvar ${classNS}::${vname}  ${nameSpace}::${vname}
				}
			}
			
			 # finally save the name of the new nameSpace	
			set ${classNS}::_sharedNS $nameSpace
			return	
		}
		export SHARE_CLASS_VARS
	}
}


 # This command is available within class definitions.
 #  ..same rules as for the "method" command:
 #    by default,  classmethod names starting with lower-case letters
 #    can be called from the outside
 #      e.g.   theClass theClassMethod ..args...
 #    see also CLASS_EXPORT and CLASS_UNEXPORT 
 #
 # .. just a syntactic sugar
proc oo::define::CLASS_METHOD {name args body} {
	uplevel [list self method $name $args $body]
}

 # This command is available within class definitions.
 #
 # .. just a syntactic sugar
proc oo::define::CLASS_EXPORT {args} {
	uplevel [list self export {*}$args ]
}

 # This command is available within class definitions.
 #
 # .. just a syntactic sugar
proc oo::define::CLASS_UNEXPORT {args} {
	uplevel [list self unexport {*}$args ]
}

 # This command is available within class definitions.
 #
 # It can be used for initializing all the class-variables
 #  previously declared with CLASS_VARS 
proc oo::define::CLASS_CONSTRUCTOR {script} {
	set className [lindex [uplevel info level 0] 1]
	 # define on-fly a new class-method, run it and delete it.
	uplevel [list self method classinit__ {} $script]
	uplevel [list $className classinit__]
	uplevel {self deletemethod classinit__}
}


 # This command is available within class definitions.
 #
 # It can be used for the clean-up of resources tied to class-variables
proc oo::define::CLASS_DESTRUCTOR {script} {
	 # define on-fly a new class-method named "__classWitClassVars_destructor"
	 # This method will be activated by the metaclass
	 #   OOClassvar::classWithClassVars
	 # when the class is destroyed.
	uplevel [list self method __classWitClassVars_destructor {} $script]
	uplevel [list self export __classWitClassVars_destructor]
	
	set className [lindex [uplevel info level 0] 1]
	 # 'activate' the metaclass OOClassvar::classWithClassVars (no matter if it was already activated)
	 #  so that the CLASS_DESTRUCTOR be called when the class is destroyed
	oo::objdefine $className class OOClassvar::classWithClassVars 
}

 # This command is available within class definitions.
 #
 # It declares one or more class-variables (much like the "variable" command)
proc oo::define::CLASS_VARS {vname args} {
	set varNames [list $vname {*}$args]
	uplevel [list variable {*}$varNames]
	uplevel [list self variable {*}$varNames]

	set className [lindex [uplevel info level 0] 1]
	 # 'activate' the metaclass OOClassvar::classWithClassVars (no matter if it was already activated)
	 #  so that classmethod SHARE_CLASS_VAR be added to this class
	oo::objdefine $className class OOClassvar::classWithClassVars 
}


 # This command MUST be placed at the beginning of the instance-constructor.
 #
 # It takes all the previously declared CLASS_VARS and makes them available
 # in every instance-methods (including the instance constructor/destructors).
 # In this way all the declared CLASS_VARS are shared between all instances
 # of the class. 	 
proc USE_CLASS_VARS {} {	 
	 # link (upvar) any class-variable
	 # with variables of this object's namespace  
	uplevel {
		foreach vname [info object variable [self class]] {
			my eval upvar [info object namespace [self class]]::$vname $vname
		} 
	}
}	



if 0 {
# ===  TEST  =================================================================

#
# == this is an example of  standard oo::class definition, 
#    extended with class-vars and class-methods
#

package require OOClassvar

oo::class create ChocolateFactory {
	 # == Class-Var declarations
	 #  Class-vars can be accessed in class-mathods as well in methods.
	 #  Note: only class-vars starting with a lower-case letter
	 #  can be shared outside (by using "_class_ SHARE_CLASS_VARS ?_namespace_?")
 
# ?? doc CLASS_EXPORT esporta class-methods, not class-var ...!!!
	 #  .. unless the are CLASS_EXPORTed ...  
	CLASS_VARS supplyOfMaterial
	CLASS_VARS _stats
	
	# == If you really want this class-var be shared outside,
	#  uncomment the following statement

# ?? sei sicuro ?  ..  infatti non funziona !!!	 
	# CLASS_EXPORT _stats
	
	# Typically, the class-var the class-constructor and the class-destructor 
	# are specificed before the class contructor and the class methods, but be PAY ATTENTION:
	# ALL the class-method called even indirectly by the CLASS_CONSTRUCTOR should be
	# defined BEFORE the CLASS_CONSTRUCTOR.
	# Therefore, in this example, we place the CLASS_CONSTRUCTOR after all the class-methods

	# == define here some class-methods.
	# Note: class-methods starting with a lower-case letter can be called
	# by class-methods, methods and also from the outside.
	# class-methods NOT starting with a lower-case letter are 'private' and
	#  can be called only by other class-methods.

	CLASS_METHOD _formatStats {} { 
		puts "------------------"
		parray _stats
		puts "-------------------"
	}

	CLASS_METHOD printStats {} {
		 # == call a private class-method ..
		my _formatStats
		puts "Factory's Supply of material: $supplyOfMaterial"
	}

	CLASS_METHOD canSupply {qty} {
		expr { $qty >= 0 && $qty <= $supplyOfMaterial }
	}
	
	CLASS_CONSTRUCTOR {
		 # == Initializaztion of class-vars and other stuff
		set supplyOfMaterial 1000
		set _stats(supplied)  0
		set _stats(discarded) 0
		set _stats(eaten)     0

		puts "StartUp statistics"
		 # == here we call another class-method ...
		 #    WARNING: all the class-methods called even indirectly in this CLASS_CONSTRUCTOR,
		 #             MUST be defined BEFORE.
		my printStats
	}

	CLASS_DESTRUCTOR {
		puts "Factory has ben closed."
		puts "Final statistics"
		my printStats
	}
	
	# ==
	# == here we continue with the standard class definitions ..
	# ==
	
	variable my ; # array for storing all the instance variables
	
	constructor {qty} {
		 # if classvars should be used in methods
		 # this statement MUST be put at the beginning of the constructor 
		 # (or just before the first use of a classvar..)		 
		USE_CLASS_VARS

		set my(qty) 0
		 # == this is the first call of a class-method from a method;
		 #    note the syntax: it should be prefixed with [self class]
		if { ! [[self class] canSupply $qty] } {
			error "Factory cannot supply $qty units"
		}
		 # == here we update some class-vars (supplyOfMaterial, _stats(..))
		 #   and some instance-vars (my(..))
		incr supplyOfMaterial -$qty
		incr _stats(supplied) $qty
		set my(qty) $qty
	}
	
	method eat {dqty} {
		if { $dqty < 0 || $dqty > $my(qty) } {
			error "only $my(qty) units in this lot"
		}
		incr my(qty) -$dqty
		incr _stats(eaten) $dqty
		return
	}

	method discard {dqty} {
		if { $dqty < 0 || $dqty > $my(qty) } {
			error "only $my(qty) units in this lot"
		}
		incr my(qty) -$dqty
		incr _stats(discarded) $dqty
		return
	}
	
	destructor {
		if { $my(qty) > 0 } {
			puts "discarding the remaining $my(qty) units"
			my discard $my(qty)
			 #
			[self class] printStats 
		}
	}
}

 # --- Usage -----
proc SimpleLineTracing {script} {
    puts stderr "### Start of line tracing ###"
	foreach line [split $script \n] {
		puts stderr "(trace) $line"
		if { [regexp {^[[:space:]]*#} $line] } continue
		if { [regexp {^[[:space:]]*$} $line] } continue
		set err [catch {uplevel $line} res]
#		puts "(  -->) [uplevel $line]"
		puts -nonewline stderr "(  -->)"
		if { $err } { puts -nonewline stderr " #ERROR#" }
		puts stderr " $res"
	}
}

SimpleLineTracing {

set pack1 [ChocolateFactory new 100]
set pack2 [ChocolateFactory new 100]
$pack1 eat 30
$pack2 discard 20
$pack2 eat 50
ChocolateFactory printStats
$pack1 destroy
ChocolateFactory printStats
set bigPack [ChocolateFactory new 1000] ;# error not enough supplyOfMaterials
 # == how to refill the ChocolateFactory ?
 #    we could have defined some class-metods for refilling the ChocolateFactory
 #    but we didn't ...
 #   So, we share all the non-private class-var in a namespace named .. ChocolateFactory
 #    and then get/set those class-var !
ChocolateFactory SHARE_CLASS_VARS
 # == now the classvar "supplyOfMaterials" is shared in the ChocolateFactory namespace
incr ChocolateFactory::supplyOfMaterial 2000
 # retry to get a bigPack ..
set bigPack [ChocolateFactory new 1000] ;# OK
ChocolateFactory printStats 
ChocolateFactory destroy
 # this is the end. Note that the ChocolateFactory namespace used for sharing
 #  the class-vars has disappeared.
 # Also note that when class is destroyed, then all the remaining instances are destroyed
 # *after* the class-destruction, but the class-variables and the class-methods
 # are still accessible by the instance destructor.  

}

}
# =============================================================================



if 0 {
 **DESIGN NOTES **
 -----------------
 The design of this package was inspired on the features of the "oo::util" package and
 the extensive discussions on wiki.tcl.tk.
 
 The goal of this package is to extend the TclOO package providing an easier way
 to define and use class-methods and class-variables ..
 The above referenced package "oo::util" provides these features, but I felt that
 it was not so complete, in particular:
  * it lacks an easy way to initialize the class-variables
    ( ->  the solution is to add a "class-constructor")
  * it lacks an easy ways to clean-up resources tied to class-variables when the whole
    class is destroyed
    ( -> the solution is to add a "class-destructor" )
  * it requires that every method using class-variables declares these class-variable
  * ( -> the solution is that class-variables be accessible in every method without
         repeating re-declaring them, much like instance-variables are accessible
         in every method without declaring "my variable ...." )
  * it lacks an (optional) easy way to share the class-variables
    from outside of the class, much like snit "typevariables" are handled
    (-> the solution is to share these class-variables in a new explicitly named namespace)
	
  Differently from the "oo::util" implementation, this package does NOT provide
  the inheritability of class-methods in derived classes. 
  In this implementation I simply removed this requirements,
  for a simpler internal implementation.
  
		class-methods are not inherited by derived class. stop.
		If you need to extend a class-method in a derived class,
		you should explicitely write some sort of delegation/forward ...
}