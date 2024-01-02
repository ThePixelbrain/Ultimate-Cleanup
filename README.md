# Changes required to cleanup Bedcraft Ultimate

The goal of this project is to make Bedcraft's FTB Ultimate 1.4.7 server more maintainable and easier adaptable to new changes.

## TickThreading
TickThreading uses `Thread.stop(Throwable)` to force kill threads when detecting a deadlock.

This throws an `UnsupportedOperationException` in J8 which isn't caught and causes the whole DeadlockDetector to crash.

Possible fixes:
- Use `Thread.stop()` instead, without the Throwable. Uncertain of the effects of removing the Exception. Probably causes further issues.
- Try/Catch `Thread.stop(Throwable)` and simply always restart on deadlocks (is recovery even common anyways?)

## Failure on plugin load with Java 8
This is automatically fixed by Nilloader or UpsilonFixes (not sure what exactly). Probably has something to do with ASM versions, investigation might be wise.

## Enhanced FakePlayer support
This consists of the `BukkitInterop` class in the main server jar and many random bytecode patches in mods. It's used for registering mod block actions as FakePlayers for plugins like UXELPROTECT to handle.

There is also `EventInteropUltimate` which basically does the same, however I didn't find the actual implementation of `hasPermissions()`.

All these methods in these mods currently call `BukkitInterop` or `EventInteropUltimate`:

| Mod           | Class                                           | FakePlayer Name     |
| :------------ | :---------------------------------------------- | :------------------ |
| GraviGun      | `gravigun/common/core/EntityHelper.java`        | GravityGun          |
|               | `gravigun/common/entity/EntityBlock.java`       | GravityGun2         |
| IC2           | `ic2/core/ExplosionIC2.java`                    | EXPLOSIVE           |
|               | `ic2/core/block/EntityDynamite.java`            | DYNAME              |
|               | `ic2/core/item/tool/EntityMiningLaser.java`     | LASER               |
| PortalGun     | `portalgun/common/core/EntityHelper.java`       | PortalGun           |
|               | `portalgun/common/entity/EntityBlock.java`      | PortalGun2          |
|               | `portalgun/common/entity/EntityPortalBall.java` | PortalGun2          |
| Buildcraft    | `buildcraft/builders/FillerFlattener.java`      | Filler              |
|               | `buildcraft/builders/FillerPattern.java`        | Filler              |
| ComputerCraft | `dan200/turtle/shared/TileEntityTurtle.java`    | Computercraft\<ID\> |
| RedPowerCore  | `com/eloraam/redpower/core/FrameLib.java`       | FRAME               |

Possible solution:
- `BukkitInterop` requires access to the Bukkit event system. Therefore it should be a plugin with an API.
- Something to inject all the hooks into all the mods. I'm currently favouring a NilMod.

Redoing this also allows to make the fakeplayer names less stupid and easier to use.

## Interop
This is an API used by Uxels plugins to abstract version dependent implementation of item related interactions (NBT, etc.) that are not exposed through the bukkit api. It consists of some classes in the main server jar.

I'm not entirely sure what is actually required, as the Ultimate jar also has a TPPI Interop class? (Maybe Uxel just patched that in because it was easier that way?). There are also two versions of Interop, maybe this relates to two different API versions?

This should probably be a plugin instead of random patches in the main server jar.

TODO: Investigate what is required by the plugins and adept a structure to apply that.

> Dummy interop is something wrong ?!? probably!

## UXELEnergyNet
This is Uxels custom implementation of the IC2 energy net. It was built to be faster than the original IC2 implementation.
The classes are all in the main server jar.

This **really** should just be a mod. It probably isn't because Uxel didn't get a working toolchain running to compile 1.4.7 mods, which is understandable from when he did this. We are well able to do this now though (Retro ForgeGradle and Voldeloom), so we should.

To make this a mod, we need to make the `UXELEnergyNet.class` a (dummy) coremod. Bytecode patches currently happen at `patchedMods/IC2.jar`. So either Nilmod or plain Forge coremod.

TickThreading also applies patches to the same class. This may result in unexpected behaviour and must be fixed somehow.

## UXELAsyncBee
Basically exactly the same as UXELEnergyNet, but for Forestry bees.

## UXELWrathIgniterLampWorker
Multithreaded WraithLamp Worker. (Has nothing to do with the Wraith Igniter despite the name.) Was patched into Factorization directly. Call also exists in `patchedMods` version.

Similar handling to UXELEnergyNet required.

## Other bytecode changes
Other bytecode changes. Some are resonable, some will be obsolete, others I don't even understand why they're there. ¯\\\_(ツ)\_/¯

| Mod                | Class                                                              | Description                                                                                                           |
| :----------------- | :----------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------- |
| IC2                | `ic2/core/block/machine/tileentity/TileEntityMatter.java`          | Has a safe input of 8192 EU/t                                                                                         |
|                    | `ic2/core/block/wiring/TileEntityTransformer.java`                 | Interal power buffer multiplied by 64                                                                                 |
|                    | `ic2/core/block/wiring/TileEntityTransformer.java`                 | Transformer sends up to 21 packets/tick                                                                               |
| PortalGun          | `portalgun/common/tileentity/TileEntityHEP.java`                   | TODO: Look at deobfuscated source                                                                                     |
| TickThreading      | `nallar/tickthreading/minecraft/profiling/EntityTickProfiler.java` | Show dim in Profiler command                                                                                          |
|                    | `nallar/tickthreading/patcher/ClassRegistry.java`                  | Patches out the patcher to prevent overwrite of manual jar patches                                                    |
| Buildcraft         | `buildcraft/core/Version.java`                                     | Remove dead version checker                                                                                           |
| ComputerCraft      | `dan200/computer/core/Computer.java`                               | Part of `queueLuaEvent` has been synchronized over a random int[] called `uxel` instead of `this` for unknown reasons |
|                    | `lua/rom/programs/http/pastebin`                                   | Pastebin API with https                                                                                               |
| Forestry           | `forestry/apiculture/genetics/AlleleEffectNone.java`               | Probably related to UXELAsyncBee                                                                                      |
| RedPowerCore       | `com/eloraam/redpower/base/TileAdvBench.java`                      | Synchronized variables, maybe dupe bug prevention?                                                                    |
|                    | `com/eloraam/redpower/core/CoreLib.java`                           | TODO: Look at deobfuscated                                                                                            |
|                    | `com/eloraam/redpower/core/FrameLib.java`                          | Prevent move of item id 516 and 1053                                                                                  |
| RedPowerMechanical | `com/eloraam/redpower/machine/TileFrameMoving.java`                | Cooldown for Frames                                                                                                   |
|                    | `com/eloraam/redpower/machine/TileMotor.java`                      | TODO: Bigger changes, look in detail (patchedMods)                                                                    |
| Tubestuff          | `immibis/tubestuff/ContainerAutoCraftingMk2.java`                  | `BasicInventory.mergeStackIntoRange` yeeted out                                                                       |
| ChickenChunks      | `codechicken/chunkloader/ChunkLoaderManager.java`                  | Reversed calls to `loadLoginTimes()`, makes online in the last X hours requirement actually work                      |
