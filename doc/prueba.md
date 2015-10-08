Contenidos
==========

Un breve recorrido por los sistemas operativos
==============================================

Generaciones de los sistemas operativos
---------------------------------------

Sistemas operativos más usuales
-------------------------------

La figura del administrador de sistemas
=======================================

Rol
---

### El administrador de sistemas

-   Dedicación del :

    -   \(\rightarrow\) Una persona encargada **solo** de la administración.

    -   \(\rightarrow\) Comparte la labor de administración con otro tipo de trabajo.

-   Labores del :

    -   \(\rightarrow\) sería uno de los miembros del .

    -   \(\rightarrow\) puede hacer todo o casi todo el trabajo del :

        -   Atender al teléfono, al fax, administrar los ordenadores...

        -   Ordenar pedidos, atender a los usuarios, desarrollar *software*, reparar *hardware*, reírse de los chistes del jefe...

### El administrador de sistemas

-   ¿Qué se espera del ?

    -   Amplios conocimientos de todo el sistema: *hardware*, *software*, datos, usuarios...

    -   Capacidad reconocida para tomar decisiones.

    -   Ambición y espíritu de superación.

    -   Eficacia y moral irreprochables.

    -   Responsabilidad: se trabaja con datos muy importantes, hay un jefe por encima...

Tareas detalladas
-----------------

### Tareas detalladas: nivel más *hardware*

-   Planificar y administrar el :

    -   Diseñar la habitación, especificar el sistema de refrigeración, las conexiones de energía, el control del entorno (alarma contraincendios, seguridad física...).

-   Planificar los para realizar actualizaciones o para administrar los dispositivos.

-   Localizar, reparar y reemplazar componentes defectuosos (a nivel *hardware*).

-   Configurar y mantener la entre los *hosts* (redes):

    -   Monitorización.

    -   Resolución de problemas.

    -   Calidad de servicio.

-   Instalar y mantener dispositivos del sistema, *hardware* y *drivers*. Especificar dispositivos soportados.

### Tareas detalladas: mantenimiento *software* y documentación

-   Mantenimiento *software*:

    -   Instalación y configuración de sistemas operativos.

    -   Detección de problemas en el *software* y reparación.

    -   Configurar y mantener aplicaciones de negocio:

        -   Aplicaciones propias (p.ej. Sigma en la UCO).

        -   *e-mail*.

        -   Agendas, calendarios...

-   Documentación:

    -   Documentar todo el sistema.

    -   Mantener documentos sobre configuraciones locales y políticas locales.

### Tareas detalladas: soporte a usuarios

![image](../jpg/itcrowd.jpg)

-   a los usuarios en el manejo del *software* y en seguridad.

-   Ayudar a los usuarios y proporcionar .

-   Establecer un sistema de rastreo de problemas para contestar las cuestiones de los usuarios (sistema Hermes de la UCO, notificación de incidencias).

-   Asegurar que los usuarios tiene acceso a toda la .

### Tareas detalladas: servicios

-   Instalar y mantener las , desarrollar aceptables y de nombrado de usuarios, instalar/configurar/administrar , manejar las licencias de *software*...

-   Determinar los requisitos *software*, los a instalar, los a proporcionar y cuáles deshabilitar.

-   Configurar los de red (con sus políticas y sus requisitos de **seguridad**):

    -   Impresión, ficheros compartidos, servicio de nombres...

-   Instalar, configurar y administrar servidores *web*.

### Tareas detalladas: seguridad

-   Determinar , políticas de y monitorizar los ficheros de `log`.

-   Configurar y manejar la :

    -   Seguridad para aplicaciones de negocio.

    -   Lectura de listas de correo de seguridad y de notificaciones CERT, SNORT (reglas *firewall* liberadas, pago por alertas inmediatas).

    -   Instalar y configurar *firewall* para limitar el acceso de intrusos.

    -   Recabar evidencias en caso de intrusión y limpiar el rastro.

### Tareas detalladas: copias de seguridad

-   Configurar y mantener *backups* del sistema:

    -   Determinar la estrategia y las políticas de copias de seguridad.

    -   Configurar el *software* de copia.

    -   Realizar/automatizar copias.

    -   Mantener *logs*.

    -   Comprobar la integridad de las copias.

    -   Determinar planes de supervivencia a catástrofes.

    -   Realizar restauraciones.

Estrategias
-----------

### El administrador de sistemas

-   Estrategia del al realizar una tarea:

    1.  antes de hacer los cambios, haciendo un estudio detallado de los pasos que hay que realizar.

    2.  Hacer los , haciendo copia de seguridad del sistema o de los ficheros de configuración a modificar.

    3.  Realizar los , probándolos si fuese posible (más fácil localizar los fallos).

    4.  , ..., antes de hacerlo público.

    5.  Conocer trabajan las cosas.

-   Cuando se realice cualquier modificación:

    -   Precaución antes de...

    -   Probarlo después de...

### El administrador de sistemas

-   Es una buena idea disponer de un cuaderno de bitácora:

    -   En el se registran todos los cambios realizados sobre la configuración del sistema.

    -   Sirve para uno mismo y para los demás.

-   La mayoría de las veces tendremos que editar múltiples ficheros de configuración, para lo que necesitaremos un .

    -   `vi` (o su versión mejorada `vim`) es un editor estándar, que podremos encontrar en cualquier sistema GNU/Linux.

    -   `pico` es más simple de utilizar.

    -   Muchas veces solo podremos acceder al servidor por conexión `ssh`, en modo consola, por lo que no podremos utilizar editores gráficos como `gedit`.

Software libre
==============

¿Qué es GNU/Linux?
------------------

### ¿Qué es GNU/Linux?

-   :

    -   En agosto de 1991, el estudiante finlandés , presenta en Internet la del kernel de un nuevo SO, inspirado en MINIX (aunque sin código de MINIX).

    -   Esta primera versión tenía poco más de 10.000 líneas de código.

    -   En 1992, Linux . A través de Internet, muchos programadores se unieron al proyecto.

    -   En 1994 Linux alcanzó la .

    -   En 2003, llegamos a la , con casi 6 millones de líneas de código.

    -   En 2011, .

    -   En 2015, (última 4.3[1])

### ¿Qué es GNU/Linux?

-   :

    -   El proyecto GNU (*GNU’s Not Unix*) fue iniciado en 1983 por bajo los auspicios de la *Free Software Foundation*[2].

    -   Objetivo: crear un sistema operativo completo basado en software libre, incluyendo herramientas de desarrollo de software y aplicaciones

    -   En el momento de la liberación, GNU no tenía listo su kernel:

        -   Linux fue adaptado para trabajar con las aplicaciones de GNU: Sistema GNU/Linux:
            Kernel Linux +
            Aplicaciones GNU: compilador (`gcc`), librería C (`glibc`) y depurador (`gdb`), *shell* `bash`, GNU Emacs, GNOME, Gimp,...

        -   GNU tiene ahora su propio kernel:

Software libre para la administración de sistemas
-------------------------------------------------

### Uso de software libre en equipos informáticos

![image](../jpg/share.png)
Fuente:

Superusuario dentro del sistema
===============================

De usuario a superusuario
-------------------------

[fragile]

### El superusuario o administrador

-   El administrador o superusuario es el usuario que tiene siempre todos los privilegios sobre cualquier fichero, instrucción u orden del sistema.

-   En ese usuario es **root**, que pertenece al grupo **root**:

    -   Directorio HOME: `/root` (o `/` en modo monousuario).

    -   Si estamos en el sistema utilizando cualquier otro usuario, ¿cómo podemos ?

        -   Salir de la sesión y entrar utilizando **root** como nombre de usuario (deshabilitado por defecto en algunos entornos).

        -   Utilizar el comando `su` \(\rightarrow\) nos pedirá la contraseña de **root** y abrirá una `shell` donde tendremos .

[fragile]

### El superusuario o administrador

    pagutierrez@TOSHIBA:~$ whoami
    pagutierrez
    pagutierrez@TOSHIBA:~$ su
    Contrasena: 
    root@TOSHIBA:/home/pagutierrez# whoami
    root

[fragile]

### La herramienta sudo

![image](../jpg/sudo.png)

-   `sudo` permite a otros usuarios ejecutar órdenes como si fuesen el administrador.

    -   `/etc/sudoers` \(\Rightarrow\) fichero de configuración

        -   Fichero de solo lectura, incluso para `root`.

        -   En él estableceremos “quién puede ejecutar qué y cómo” desde sudo.

[fragile]

### La herramienta sudo

![image](../jpg/sudo.png)

-   `visudo` \(\Rightarrow\) orden para modificar el fichero de configuración `/etc/sudoers`.

        # Especificacion de privilegios de usuario
        root    ALL=(ALL:ALL) ALL
        # Los miembros del grupo sudo podran ejecutar cualquier comando
        %sudo   ALL=(ALL:ALL) ALL

-   `sudo orden` \(\Rightarrow\) pide contraseña del usuario.

Comunicación con el resto de usuarios
-------------------------------------

[fragile]

### Comunicación con el resto de usuarios

-   El debe comunicarse con el resto de usuarios:

    -   `write`: enviar un mensaje a un usuario

    -   `talk`: conversar con un usuario, incluso aunque esté en otra máquina GNU/Linux.

    -   `mesg [y/n]`: habilitar/deshabilitar la llegada de mensajes al terminal.

    -   `wall`: mandar un mensaje a todos los usuarios del sistema.

    -   Fichero `/etc/motd`: contiene el mensaje del día que se imprime justo después de entrar al sistema (en modo texto).

        -   Fichero `$HOME/.hushlogin` \(\Rightarrow\) permite evitar el mensaje del día.

    -   Fichero `/etc/issue`: contiene el mensaje que se muestra antes del login, normalmente muestra la versión de Linux (en modo texto).

Referencias
===========

[1] <https://www.kernel.org/>

[2] Noticia: <https://groups.google.com/forum/m/#!msg/net.unix-wizards/8twfRPM79u0/1xlglzrWrU0Jy>
