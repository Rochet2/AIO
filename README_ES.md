Leer en: [Inglés :gb:](README.md) | [Español :es:](README_ES.md)

# AIO

AIO es un sistema de comunicación cliente-servidor puro en lua para Eluna y WoW.

AIO está diseñado para enviar complementos y datos de lua desde el servidor al jugador y datos del jugador al servidor.

Hecho para [Eluna Lua Engine](https://github.com/ElunaLuaEngine/Eluna). Probado en 3.3.5a y debería funcionar en otros parches. Probado con Lua 5.1 y 5.2.

[El soporte de C++ de terceros lo proporciona SaiFi0102](https://github.com/SaiFi0102/TrinityCore/blob/CAIO-3.3.5/CAIO_README.md). Esto te permite usar AIO sin necesidad de Eluna.

Enlace de retroceso: https://github.com/Rochet2/AIO

# Instalación

- Asegúrate de tener [Eluna Lua Engine](https://github.com/ElunaLuaEngine/Eluna)
- Copia `AIO_Client` en tu carpeta `WoW_instalación/carpeta/Interface/AddOns/`
- Copia `AIO_Server` en tu `server_root/lua_scripts/`
- Consulta la configuración en el archivo AIO.lua. Puedes ajustar tanto el archivo del servidor como el del cliente respectivamente
- Cuando desarrolles un complemento, se recomienda tener `AIO_ENABLE_PCALL off` y, a veces, es posible que necesites `AIO_ENABLE_DEBUG_MSGS on` para ver información sobre lo que está sucediendo.

# Acerca de

AIO funciona de manera que el servidor y el cliente tienen sus propios scripts lua que gestionan el envío y la recepción de mensajes entre sí.
Cuando se agrega un complemento a AIO para enviarlo al cliente, será procesado (dependiendo de la configuración, ofuscado y comprimido) y almacenado en memoria para esperar ser enviado a los jugadores.
Todos los complementos que se agregan se ejecutan en el lado del cliente en el orden en que fueron agregados a AIO.
AIO utiliza un sistema de caché para almacenar en caché los códigos de los complementos en el lado del cliente, de modo que no sea necesario enviarlos en cada inicio de sesión.
Solo si un complemento cambia o se agrega, se enviará nuevamente el complemento nuevo. El usuario también puede borrar su caché local de AIO, en cuyo caso los complementos se enviarán nuevamente.
El código completo del complemento enviado al cliente se ejecuta tal cual en el cliente. El código tiene acceso completo a la API del complemento del lado del cliente.
La mensajería cliente-servidor se gestiona con una clase de ayuda de mensajes de AIO. Esta clase almacena y gestiona los datos para enviarlos.

# Comandos

Hay algunos comandos que pueden ser útiles.

En el lado del cliente usa `/aio help` para ver la lista. En el lado del servidor usa `.aio help` para ver la lista.

# Seguridad

La mensajería entre el servidor y el cliente está codificada para ser segura

- Puedes limitar los tamaños de caché, los retrasos y otros en AIO.lua
- Los datos recibidos desde el cliente solo se deserializan, sin compresión, etc.
- La biblioteca de serialización no utiliza `loadstring` para hacer la deserialización segura
- Al recibir mensajes, el código se ejecuta en `pcall` para evitar que todos los datos enviados por el usuario creen errores. Activa los mensajes de depuración en AIO.lua para ver todos los errores en el lado del servidor también
- El código es tan seguro como tú lo hagas. En tus propios códigos, asegúrate de que todos los datos que el cliente envíe al servidor y que uses sean del tipo que esperas y estén en el rango que esperas. (ejemplo: `math.huge` es un tipo de número, pero no un número real)
- Asegúrate de que tu código tenga afirmaciones y sea rápido. Hay un tiempo de espera ajustable en AIO.lua solo para asegurarte de que el servidor no se cuelgue si escribes un código incorrecto o vulnerable, o si un usuario malintencionado encuentra una manera de bloquear el sistema.
- Revisa la configuración en AIO.lua y ajústala a tus necesidades tanto en el cliente como en el servidor. Esto es importante para defenderse de usuarios maliciosos y hacer que todo funcione mejor con tu configuración.

# Handlers

AIO tiene algunos handlers por defecto que se utilizan para los códigos internos y puedes usarlos si lo deseas.

También puedes programar tus propios handlers y agregarlos a AIO con las funciones descritas en la sección de API. Consulta AIO.RegisterEvent(name, func) y AIO.AddHandlers(name, handlertable)

```lua
-- Forzar la recarga de la UI del jugador
-- Muestra un mensaje de que la UI está siendo recargada y recarga la UI cuando el jugador
-- hace clic en cualquier parte de su pantalla.
AIO.Handle(player, "AIO", "ForceReload")

-- Forzar el reinicio de la UI del jugador
-- Reinicia las variables guardadas del complemento AIO y muestra un mensaje de que la UI está siendo recargada
-- y recarga la UI cuando el jugador hace clic en cualquier parte de su pantalla.
AIO.Handle(player, "AIO", "ForceReset")
```

# API

Para ejemplos de scripts, consulta la carpeta Examples. Los archivos de ejemplo están nombrados de acuerdo con su ubicación de ejecución final. Para ejecutar los ejemplos, coloca todos sus archivos en `server_root/lua_scripts/`.

Hay algunos comandos del lado del cliente. Usa el comando de barra `/aio` en el juego para ver la lista de comandos.

```lua
-- AIO es necesario de esta manera debido a las diferencias de servidor y cliente con la función require
local AIO = AIO or require("AIO")

-- Devuelve true si estamos en el lado del servidor, false si estamos en el lado del cliente
isServer = AIO.IsServer()

-- Devuelve la versión de AIO - ten en cuenta que el tipo no está garantizado a ser un número
version = AIO.GetVersion()

-- Agrega el archivo en la ruta dada a los archivos que se enviarán a los jugadores si se llama en el lado del servidor.
-- El código del complemento se recorta según la configuración en AIO.lua.
-- El complemento se almacena en caché en el lado del cliente y solo se actualizará cuando sea necesario.
-- Devuelve false en el lado del cliente y true en el lado del servidor. Por defecto, la
-- ruta es la ruta del archivo actual y el nombre es el nombre del archivo.
-- 'path' es relativo a worldserver.exe, pero también se puede dar una ruta absoluta.
-- Debes llamar a esta función solo al inicio para asegurar que todos reciban los mismos
-- complementos y que no haya duplicados.
added = AIO.AddAddon([path, name])

-- La forma en que se debe usar es al principio de un archivo de complemento para que el
-- archivo se agregue y no se ejecute si estamos en el servidor, y simplemente se ejecute si estamos en el cliente:
if AIO.AddAddon() then
    return
end

-- Similar a AddAddon - Agrega 'code' a los complementos enviados a los jugadores. El código es recortado
-- según la configuración en AIO.lua. El complemento se almacena en caché en el lado del cliente y se
-- actualizará solo cuando sea necesario. 'name' es un nombre único para el complemento, generalmente
-- puedes usar el nombre del archivo o el nombre del complemento allí. Ten en cuenta que los nombres cortos son
-- mejores, ya que se envían de ida y vuelta para identificar los archivos.
-- Esta función solo existe en el lado del servidor.
-- Debes llamar a esta función solo al inicio para asegurarte de que todos reciban los mismos
-- complementos y que no haya duplicados.
AIO.AddAddonCode(name, code)

-- Dispara la función handler que tiene el nombre 'handlername' de la tabla de handlers
-- agregada con AIO.AddHandlers(name, handlertable) para el 'name'.
-- También puede disparar una función registrada con AIO.RegisterEvent(name, func)
-- Todos los handlers disparados tienen parámetros handler(player, ...) donde los varargs son
-- los varargs en AIO.Handle o msg.Add
-- Esta función es una forma abreviada de AIO.Msg():Add(name, handlername, ...):Send()
-- Para mayor eficiencia, es mejor crear los mensajes una vez y enviarlos en lugar de crearlos
-- una y otra vez con AIO.Handle().
-- La versión del lado del servidor.
AIO.Handle(player, name, handlername[, ...])

-- La versión del lado del cliente.
AIO.Handle(name, handlername[, ...])

-- Agrega una tabla de funciones handler para el 'name' especificado. Cuando se recibe un mensaje como:
-- AIO.Handle(name, "HandlerName", ...) se llamará handlertable["HandlerName"]
-- con player y varargs como parámetros.
-- Devuelve la 'handlertable' pasada.
-- AIO.AddHandlers usa AIO.RegisterEvent internamente, por lo que no se puede usar el mismo nombre en ambos.
handlertable = AIO.AddHandlers(name, handlertable)

-- Agrega una nueva función de callback que se llama si se recibe un mensaje con el nombre dado.
-- Todos los parámetros que el remitente envía en el mensaje se pasarán a func cuando se llame.
-- Ejemplo de mensaje: AIO.Msg():Add(name, ...):Send()
-- AIO.AddHandlers usa AIO.RegisterEvent internamente, por lo que no se puede usar el mismo nombre en ambos.
AIO.RegisterEvent(name, func)

-- Agrega una nueva función que se llama cuando el mensaje inicial es enviado al jugador.
-- La función se llama antes de enviar y se le pasa el mensaje inicial
-- junto con el jugador si está disponible: func(msg[, player])
-- En la función puedes modificar el mensaje pasado y/o devolver un nuevo mensaje que será
-- usado como el mensaje inicial. Solo en el lado del servidor.
-- Esto se puede usar para enviar, por ejemplo, valores iniciales (como estadísticas del jugador) para los complementos.
-- Si se prefiere la carga dinámica, también puedes usar la API de mensajería para solicitar los valores
-- bajo demanda.
AIO.AddOnInit(func)

-- Key es una clave para una variable en la tabla global _G.
-- La variable se almacena cuando el jugador cierra sesión y se restaurará
-- cuando vuelva a iniciar sesión antes de que se ejecuten los códigos de complemento.
-- Estas variables están vinculadas a la cuenta.
-- Solo existe en el lado del cliente y debes llamarla solo una vez por clave.
-- Todos los datos guardados se almacenan en el lado del cliente.
AIO.AddSavedVar(key)

-- Key es una clave para una variable en la tabla global _G.
-- La variable se almacena cuando el jugador cierra sesión y se restaurará
-- cuando vuelva a iniciar sesión antes de que se ejecuten los códigos de complemento.
-- Estas variables están vinculadas al personaje.
-- Solo existe en el lado del cliente y debes llamarla solo una vez por clave.
-- Todos los datos guardados se almacenan en el lado del cliente.
AIO.AddSavedVarChar(key)

-- Hace que el marco del complemento guarde su posición y la restaure al iniciar sesión.
-- Si char es true, el guardado de la posición está vinculado al personaje, de lo contrario está vinculado a la cuenta.
-- Solo existe en el lado del cliente y debes llamarla solo una vez por marco.
-- Todos los datos guardados se almacenan en el lado del cliente.
AIO.SavePosition(frame[, char])

-- Clase de mensaje AIO:
-- Crea y devuelve un nuevo mensaje AIO al que puedes agregarle cosas y enviarlo al
-- cliente o al servidor. Ejemplo: AIO.Msg():Add("MyHandlerName", param1, param2):Send(player)
-- Estos mensajes gestionan toda la comunicación cliente-servidor.
msg = AIO.Msg()

-- El nombre se usa para identificar la función handler en el extremo receptor.
-- Una función handler registrada con AIO.RegisterEvent(name, func)
-- será llamada en el extremo receptor con los varargs.
function msgmt:Add(name, ...)

-- Agrega mensajes entre sí, devuelve el mensaje
msg = msg:Append(msg2)

-- Envía el mensaje, devuelve el mensaje
-- Versión del lado del servidor - lo envía a todos los jugadores pasados
msg = msg:Send(player, ...)
-- Versión del lado del cliente - lo envía al servidor
msg = msg:Send()

-- Devuelve true si el mensaje tiene algo en él
hasmsg = msg:HasMsg()

-- Devuelve el mensaje como una cadena
msgstr = msg:ToString()

-- Borra el mensaje creado hasta ahora y devuelve el mensaje
msg = msg:Clear()

-- Ensambla la cadena del mensaje a partir de los datos agregados y añadidos. Principalmente para uso interno.
-- Devuelve el mensaje
msg = msg:Assemble()
```

# Dependencias incluidas

No necesitas obtener estas, ya están incluidas:

- Serializador de Lua: https://github.com/gvx/Smallfolk
- Lua crc32: https://github.com/davidm/lua-digest-crc32lua
- Cola de Lua con modificaciones: http://www.lua.org/pil/11.4.html
- Compresión para datos de cadenas: https://github.com/Rochet2/lualzw/tree/zeros
- Ofuscación para el código del complemento: http://luasrcdiet.luaforge.net/
- Guardado de posición de los marcos de los complementos enviados: http://www.wowace.com/addons/libwindow-1-1/

# Agradecimientos especiales

- Kenuvis < [Gate](http://www.ac-web.org/forums/showthread.php?148415-LUA-Gate-Project), [ElunaGate](https://github.com/ElunaLuaEngine/ElunaGate) >
- Laurea/alexeng/Kyromyr < [Alexeng en GitHub](https://github.com/Alexeng), [Kyromyr en GitHub](https://github.com/Kyromyr) >
- Foereaper < [Foereaper en GitHub](https://github.com/Foereaper) >
- SaiF < [SaiFi0102 en GitHub](https://github.com/SaiFi0102) >
- Eluna team < [Eluna Team en GitHub](https://github.com/ElunaLuaEngine/Eluna#team) >
- Contribuidores de Lua < [Lua.org](http://www.lua.org/) >
